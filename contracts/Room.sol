// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IERC20.sol";
import "forge-std/console2.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";


//1. room factory  @john
//2. tokenomics / emissions @john
//3. game @webber

contract Room {
    using SafeCast for uint256;
    using SafeCast for int16;

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/
    uint8 internal constant _not_entered = 1;
    uint8 internal constant _entered = 2;
    uint8 internal _entered_state = 1;

    modifier nonreentrant() {
        require(_entered_state == _not_entered);
        _entered_state = _entered;
        _;
        _entered_state = _not_entered;
    }

    struct Wolf {
        int16 x;
        int16 y;
        address owner;
        uint32 id; //唯一id
        uint32 blood; //血量
        uint32 bornTime; //出生时间
        uint32 updateTime; //更新时间
        uint256 height;
        uint256 value; //当前资产价值
    }

    struct Sheep {
        int16 x;
        int16 y;
        address owner;
        uint32 id; //唯一id
        uint32 blood; //血量
        uint32 bornTime; //出生时间
        uint32 updateTime; //更新时间
        uint256 height;
        uint256 value; //当前资产价值
    }

    struct Grass {
        int16 x;
        int16 y;
        address owner;
        uint32 id; //唯一id
        uint32 bornTime; //出生时间
        uint32 updateTime; //更新时间
        uint256 height;
        uint256 value; //当前资产价值
    }

    uint8 public constant WOLF_TYPE = 2;
    uint8 public constant SHEEP_TYPE = 1;
    uint8 public constant GRASS_TYPE = 0;

    int16 public constant paradise_x = -1;
    int16 public constant paradise_y = -1;

    //物种上限
    uint32 public WOLF_LIMIT = 32;
    uint32 public SHEEP_LIMIT = 4096;
    uint32 public GRASS_LIMIT = 32_768;

    //单个地址的物种持有上线
    uint32 public WOLF_LIMIT_OF_OWNER = 2;
    uint32 public SHEEP_LIMIT_OF_OWNER = 32;
    uint32 public GRASS_LIMIT_OF_OWNER = 128;

    uint32 public totalWolf;
    uint32 public totalSheep;
    uint32 public totalGrass;

    uint32 public globalWolfId;
    uint32 public globalSheepId;
    uint32 public globalGrassId;

    uint32 public EAT_LIMIT = 3;

    //物种价格
    uint256 public wolfPrice;
    uint256 public sheepPrice;
    uint256 public grassPrice;

    // (x,y) => creatures
    mapping(int16 => mapping(int16 => uint32[])) private wolfMap;
    mapping(int16 => mapping(int16 => uint32[])) private sheepMap;
    mapping(int16 => mapping(int16 => uint32[])) private grassMap;

    mapping(int16 => mapping(int16 => uint32)) private wolfMapNum;
    mapping(int16 => mapping(int16 => uint32)) private sheepMapNum;
    mapping(int16 => mapping(int16 => uint32)) private grassMapNum;

    mapping(address => uint32[]) private wolfOfOwner;
    mapping(address => uint32[]) private sheepOfOwner;
    mapping(address => uint32[]) private grassOfOwner;

    mapping(address => uint32) private wolfBalanceOfOwner;
    mapping(address => uint32) private sheepBalanceOfOwner;
    mapping(address => uint32) private grassBalanceOfOwner;

    // global wolf & sheep & grass
    mapping(uint32 => Wolf) private id2Wolf;
    mapping(uint32 => Sheep) private id2Sheep;
    mapping(uint32 => Grass) private id2Grass;

    uint32[] private aliveWolfs;
    uint32[] private aliveSheeps;
    uint32[] private aliveGrasses;

    address public USDT;
    address public treasury;

    constructor(
        uint256 _wolfPrice,
        uint256 _sheepPrice,
        uint256 _grassPrice,
        address _usdt,
        address _treasury
    ) {
        wolfPrice = _wolfPrice;
        sheepPrice = _sheepPrice;
        grassPrice = _grassPrice;
        USDT = _usdt;
        treasury = _treasury;
    }

    function buy(uint8 species, uint32 num) external nonreentrant {
        uint256 balance = IERC20(USDT).balanceOf(msg.sender);
        uint256 amount = num * _getPrice(species);
        require(amount <= balance, "Insufficient funds.");
        IERC20(USDT).transferFrom(msg.sender, treasury, amount);

        _buy(species, num, msg.sender);
    }

    function buy(uint8 species, uint32 num, address to) external nonreentrant {
        uint256 balance = IERC20(USDT).balanceOf(msg.sender);
        uint256 amount = num * _getPrice(species);
        require(amount <= balance, "Insufficient funds.");
        IERC20(USDT).transferFrom(msg.sender, treasury, amount);

        _buy(species, num, to);
    }

    function sell(uint8 species, uint32[] calldata ids) external nonreentrant {
        _sell(species, ids, msg.sender);
    }

    function sell(
        uint8 species,
        uint32[] calldata ids,
        address to
    ) external nonreentrant {
        _sell(species, ids, to);
    }

    function _sell(uint8 species, uint32[] calldata ids, address to) internal {
        uint256 value;
        if (species == GRASS_TYPE) {
            value = sellGrass(ids);
        } else if (species == SHEEP_TYPE) {
            value = sellSheep(ids);
        } else {
            value = sellWolf(ids);
        }

        // totalValue -> 兑换成token transfer给用户
    }

    function sellGrass(uint32[] calldata ids) internal returns (uint256) {
        uint32 balance = grassBalanceOfOwner[msg.sender];
        require(balance >= ids.length, "Insufficient balance.");

        uint8 size = 0;
        int16[] memory loc_x = new int16[](10);
        int16[] memory loc_y = new int16[](10);

        uint256 totalValue;
        for (uint32 i = 0; i < ids.length; ++i) {
            uint32 grassId = ids[i];
            Grass storage grass = id2Grass[grassId];
            require(msg.sender == grass.owner, "wrong owner.");

            // 记录<X,Y>集合
            int16 x = grass.x;
            int16 y = grass.y;
            if (size == 0) {
                loc_x[0] = x;
                loc_y[0] = y;
                ++size;
            } else {
                bool needAdd = true;
                for (uint8 j = 0; j < size; ++i) {
                    if (loc_x[j] == x && loc_y[j] == y) {
                        needAdd = false;
                        break;
                    }
                }
                if (needAdd) {
                    loc_x[size] = x;
                    loc_y[size] = y;
                    ++size;
                }
            }

            totalValue += updateGrassValue(grass.value, grass.updateTime);
            burnGrass(grassId);
        }

        // 推送地图变化
        for (uint8 i = 0; i < size; ++i) {
            int16 x = loc_x[i];
            int16 y = loc_y[i];
            action(x, y);
        }
        return totalValue;
    }

    function sellSheep(uint32[] calldata ids) internal returns (uint256) {
        uint32 balance = sheepBalanceOfOwner[msg.sender];
        require(balance >= ids.length, "Insufficient balance.");

        uint8 size = 0;
        int16[] memory loc_x = new int16[](10);
        int16[] memory loc_y = new int16[](10);

        uint256 totalValue;
        console2.log("ids : %s", ids.length);
        for (uint32 i = 0; i < ids.length; ++i) {
            uint32 sheepId = ids[i];
            Sheep storage sheep = id2Sheep[sheepId];
            require(msg.sender == sheep.owner, "wrong owner.");

            // 记录<X,Y>集合
            int16 x = sheep.x;
            int16 y = sheep.y;
            if (size == 0) {
                loc_x[0] = x;
                loc_y[0] = y;
                ++size;
            } else {
                bool needAdd = true;
                for (uint8 j = 0; j < size; ++i) {
                    if (loc_x[j] == x && loc_y[j] == y) {
                        needAdd = false;
                        break;
                    }
                }
                if (needAdd) {
                    loc_x[size] = x;
                    loc_y[size] = y;
                    ++size;
                }
            }

            totalValue += updateSheepValue(sheep.value, sheep.updateTime);
            console2.log("sheepId : %s", sheepId);
            burnSheep(sheepId);
        }
        uint32 grassNumAtMap = getSpecieNumAt(1, 1, 1);
        // console2.log("grassNumAtMap %d", grassNumAtMap);

        uint32[] memory sheepIds = getSpecieIdsAt(1, 1, 1);
        // for (uint8 i=0; i<grassNumAtMap; ++i) {
        //     console2.log("sheepIds[%s] %s", i , sheepIds[i]);
        // }

        // 推送地图变化
        for (uint8 i = 0; i < size; ++i) {
            int16 x = loc_x[i];
            int16 y = loc_y[i];
            action(x, y);
        }
        return totalValue;
    }

    function sellWolf(uint32[] calldata ids) internal returns (uint256) {
        uint32 balance = wolfBalanceOfOwner[msg.sender];
        require(balance >= ids.length, "Insufficient balance.");

        uint8 size = 0;
        int16[] memory loc_x = new int16[](10);
        int16[] memory loc_y = new int16[](10);

        uint256 totalValue;
        for (uint32 i = 0; i < ids.length; ++i) {
            uint32 wolfId = ids[i];
            Wolf storage wolf = id2Wolf[wolfId];
            require(msg.sender == wolf.owner, "wrong owner.");

            // 记录<X,Y>集合
            int16 x = wolf.x;
            int16 y = wolf.y;
            if (size == 0) {
                loc_x[0] = x;
                loc_y[0] = y;
                ++size;
            } else {
                bool needAdd = true;
                for (uint8 j = 0; j < size; ++i) {
                    if (loc_x[j] == x && loc_y[j] == y) {
                        needAdd = false;
                        break;
                    }
                }
                if (needAdd) {
                    loc_x[size] = x;
                    loc_y[size] = y;
                    ++size;
                }
            }

            totalValue += updateWolfValue(wolf.value, wolf.updateTime);
            burnWolf(wolfId);
        }

        // 推送地图变化
        for (uint8 i = 0; i < size; ++i) {
            int16 x = loc_x[i];
            int16 y = loc_y[i];
            action(x, y);
        }
        return totalValue;
    }

    function _buy(uint8 species, uint32 num, address to) internal {
        require(_paramsCheck(species, num, to), "Check params fail.");

        uint32 id;
        if (species == GRASS_TYPE) {
            id = globalGrassId;
            totalGrass += num;
        } else if (species == SHEEP_TYPE) {
            id = globalSheepId;
            totalSheep += num;
        } else {
            id = globalWolfId;
            totalWolf += num;
        }

        uint8 size = 0;
        int16[] memory loc_x = new int16[](10);
        int16[] memory loc_y = new int16[](10);

        for (uint32 i = 0; i < num; i++) {
            //1.mint
            id += 1;

            //2. generate new coordinate
            // (int16 x, int16 y) = genCoordinate(-1, -1, id);
            (int16 x, int16 y) = genCoordinateMocked();

            //3. action on (x,y)
            action(x, y);

            //4.storage
            born(species, x, y, to, id, 12345);
        }

        updateAssetUniqueId(species, id);
    }

    function _paramsCheck(
        uint8 species,
        uint32 num,
        address to
    ) internal view returns (bool) {
        if (species == GRASS_TYPE) {
            uint32[] memory grassIds = grassOfOwner[to];
            return
                num <= 10 &&
                (totalGrass + num) <= GRASS_LIMIT &&
                (grassIds.length + num) <= GRASS_LIMIT_OF_OWNER;
        }

        if (species == SHEEP_TYPE) {
            uint32[] memory sheepIds = sheepOfOwner[to];
            return
                num <= 10 &&
                (totalSheep + num) <= SHEEP_LIMIT &&
                (sheepIds.length + num) <= SHEEP_LIMIT_OF_OWNER;
        }

        if (species == WOLF_TYPE) {
            uint32[] memory wolfIds = wolfOfOwner[to];
            return
                num <= 10 &&
                (totalWolf + num) <= WOLF_LIMIT &&
                (wolfIds.length + num) <= WOLF_LIMIT_OF_OWNER;
        }
        return false;
    }

    function action(int16 _x, int16 _y) internal {
        //1. wolf
        uint32[] storage wolfIds = wolfMap[_x][_y];
        for (uint32 i = 0; i < wolfIds.length; ++i) {
            uint32 wolfId = wolfIds[i];
            Wolf storage wolf = id2Wolf[wolfId];
            if (wolf.height == block.number) {
                continue;
            }
            uint32 blood = updateBlood(wolf.blood, wolf.updateTime);
            if (blood > 0) {
                // move
                uint256 value = moveAndEat(_x, _y, wolfId, WOLF_TYPE);
                wolf.value += value;
                wolf.blood = blood;
                wolf.updateTime = uint32(block.timestamp);
                wolf.height = block.number;
            } else {
                burnWolf(wolfId);
                //emit event
            }
        }

        //2. sheep
        uint32[] storage sheepIds = sheepMap[_x][_y];
        for (uint32 i = 0; i < sheepIds.length; ++i) {
            uint32 sheepId = sheepIds[i];
            Sheep storage sheep = id2Sheep[sheepId];
            if (sheep.height == block.number) {
                continue;
            }
            uint32 blood = updateBlood(sheep.blood, sheep.updateTime);
            if (blood > 0) {
                // move
                uint256 value = moveAndEat(_x, _y, sheepId, SHEEP_TYPE);
                sheep.value += value;
                sheep.blood = blood;
                sheep.updateTime = uint32(block.timestamp);
                sheep.height = block.number;
            } else {
                burnSheep(sheepId);
                //emit event
            }
        }

        //3. grass
        uint32[] storage grassIds = grassMap[_x][_y];
        for (uint32 i = 0; i < grassIds.length; ++i) {
            uint32 grassId = grassIds[i];
            Grass storage grass = id2Grass[grassId];
            if (grass.height == block.number) {
                continue;
            }
            uint256 grassValue = updateGrassValue(
                grass.value,
                grass.updateTime
            );

            //grass growing
            grass.value = grassValue;
            grass.updateTime = uint32(block.timestamp);
            grass.height = block.number;
            //emit event;
        }
    }

    function moveAndEat(
        int16 _x,
        int16 _y,
        uint32 id,
        uint8 species
    ) internal returns (uint256) {
        // (int16 x, int16 y) = genCoordinate(_x, _y, id);
        (int16 x, int16 y) = genCoordinateMocked(_x, _y);

        uint256 value;
        if (species == WOLF_TYPE) {
            wolfMove(id, x, y);
            value = eat(x, y, SHEEP_TYPE);
        } else if (species == SHEEP_TYPE) {
            sheepMove(id, x, y);
            value = eat(x, y, GRASS_TYPE);
        }
        return value;
    }

    function eat(int16 x, int16 y, uint8 species) internal returns (uint256) {
        //1.结算新坐标(x,y)上的生物
        if (species == SHEEP_TYPE) {
            //eat sheep
            uint32[] storage sheepIds = sheepMap[x][y];
            uint256 newValue;
            //1次最多吃3只羊
            for (uint32 i = 0; i < sheepIds.length && i < EAT_LIMIT; ++i) {
                uint32 sheepId = sheepIds[i];
                Sheep storage sheep = id2Sheep[sheepId];
                uint32 blood = updateBlood(sheep.blood, sheep.updateTime);
                if (blood > 0) {
                    //羊被吃掉
                    uint256 sheepValue = updateSheepValue(
                        sheep.value,
                        sheep.updateTime
                    );
                    newValue += convert2Wolf(sheepValue);
                }

                // delete sheep
                burnSheep(sheepId);
                //emit event
            }
            return newValue;
        }

        if (species == GRASS_TYPE) {
            uint32[] storage grassIds = grassMap[x][y];
            uint256 newValue;
            //最多吃3颗草
            for (uint32 i = 0; i < grassIds.length && i < EAT_LIMIT; ++i) {
                uint32 grassId = grassIds[i];
                Grass storage grass = id2Grass[grassId];
                uint256 grassValue = updateGrassValue(
                    grass.value,
                    grass.updateTime
                );
                newValue += convert2Sheep(grassValue);

                //delete grass
                burnGrass(grassId);
                //emit event;
            }
            return newValue;
        }
        revert("wrong species.");
    }

    function wolfMove(uint32 id, int16 x, int16 y) internal {
        Wolf storage wolf = id2Wolf[id];
        int16 old_x = wolf.x;
        int16 old_y = wolf.y;

        // update old location info
        uint32 num = wolfMapNum[old_x][old_y];
        uint32[] storage wolfIds = wolfMap[old_x][old_y];
        for (uint32 i = 0; i < num; ++i) {
            if (wolfIds[i] == id) {
                wolfIds[i] = wolfIds[num - 1];
                wolfMapNum[old_x][old_y] -= 1;
            }
        }

        // update new location info
        wolf.x = x;
        wolf.y = y;
        if (x == paradise_x) {
            wolf.updateTime = 0;
            return;
        }

        wolf.updateTime = uint32(block.timestamp);
        wolfMap[x][y].push(id);
        wolfMapNum[x][y] += 1;
    }

    function sheepMove(uint32 id, int16 x, int16 y) internal {
        Sheep storage sheep = id2Sheep[id];
        int16 old_x = sheep.x;
        int16 old_y = sheep.y;

        // update old location info
        uint32 num = sheepMapNum[old_x][old_y];
        uint32[] storage sheepIds = sheepMap[old_x][old_y];
        for (uint32 i = 0; i < num; ++i) {
            if (sheepIds[i] == id) {
                sheepIds[i] = sheepIds[num - 1];
                sheepMapNum[old_x][old_y] -= 1;
                break;
            }
        }

        // update new location info
        sheep.x = x;
        sheep.y = y;
        if (x == paradise_x) {
            sheep.updateTime = 0;
            return;
        }

        sheep.updateTime = uint32(block.timestamp);
        sheepMap[x][y].push(id);
        sheepMapNum[x][y] += 1;
    }

    function burnWolf(uint32 id) internal {
        Wolf storage wolf = id2Wolf[id];
        address owner = wolf.owner;

        wolfMove(id, paradise_x, paradise_y);

        //remove from balanceOfOwner
        uint32 balance = wolfBalanceOfOwner[owner];
        uint32[] storage wolfIds = wolfOfOwner[owner];
        for (uint32 i = 0; i < balance; ++i) {
            if (wolfIds[i] == id) {
                wolfIds[i] = wolfIds[balance - 1];
                wolfBalanceOfOwner[owner] -= 1;
                break;
            }
        }

        wolf.owner = address(0);
        wolf.blood = 0;
        wolf.bornTime = 0;
        wolf.updateTime = 0;
        wolf.value = 0;

        totalGrass -= 1;
    }

    function burnSheep(uint32 id) internal {
        Sheep storage sheep = id2Sheep[id];
        address owner = sheep.owner;

        // console2.log("sheepMove begin");
        sheepMove(id, paradise_x, paradise_y);
        // console2.log("sheepMove end");

        //remove from balanceOfOwner
        uint32 balance = sheepBalanceOfOwner[owner];
        uint32[] storage sheepIds = sheepOfOwner[owner];
        for (uint32 i = 0; i < balance; ++i) {
            if (sheepIds[i] == id) {
                sheepIds[i] = sheepIds[balance - 1];
                sheepBalanceOfOwner[owner] -= 1;
                break;
            }
        }

        sheep.owner = address(0);
        sheep.blood = 0;
        sheep.bornTime = 0;
        sheep.updateTime = 0;
        sheep.value = 0;

        totalSheep -= 1;
    }

    function burnGrass(uint32 id) internal {
        Grass storage grass = id2Grass[id];
        address owner = grass.owner;
        int16 x = grass.x;
        int16 y = grass.y;

        // remove from map
        uint32 num = grassMapNum[x][y];
        uint32[] storage grassIds = grassMap[x][y];
        for (uint32 i = 0; i < num; ++i) {
            if (grassIds[i] == id) {
                // console2.log("grassIds[num-1] %s", grassIds[num-1]);
                grassIds[i] = grassIds[num - 1];
                grassMapNum[x][y] -= 1;
                break;
            }
        }

        //remove from balanceOfOwner
        uint32 balance = grassBalanceOfOwner[owner];
        uint32[] storage grassIds2 = grassOfOwner[owner];
        for (uint32 i = 0; i < balance; ++i) {
            if (grassIds2[i] == id) {
                grassIds2[i] = grassIds2[balance - 1];
                grassBalanceOfOwner[owner] -= 1;
                break;
            }
        }

        grass.x = paradise_x;
        grass.y = paradise_y;
        grass.owner = address(0);
        grass.bornTime = 0;
        grass.updateTime = 0;
        grass.value = 0;

        totalGrass -= 1;
    }

    function born(
        uint8 species,
        int16 x,
        int16 y,
        address to,
        uint32 id,
        uint256 value
    ) internal {
        if (species == GRASS_TYPE) {
            Grass memory grass = Grass(
                x,
                y,
                to,
                id,
                uint32(block.timestamp),
                uint32(block.timestamp),
                block.number,
                value
            );
            grassMapNum[x][y] += 1;
            grassMap[x][y].push(id);
            grassOfOwner[to].push(id);
            grassBalanceOfOwner[to] += 1;
            id2Grass[id] = grass;
            aliveGrasses.push(id);
        } else if (species == SHEEP_TYPE) {
            Sheep memory sheep = Sheep(
                x,
                y,
                to,
                id,
                100,
                uint32(block.timestamp),
                uint32(block.timestamp),
                block.number,
                value
            );
            sheepMapNum[x][y] += 1;
            sheepMap[x][y].push(id);
            sheepOfOwner[to].push(id);
            sheepBalanceOfOwner[to] += 1;
            id2Sheep[id] = sheep;
            aliveSheeps.push(id);
        } else {
            Wolf memory wolf = Wolf(
                x,
                y,
                to,
                id,
                100,
                uint32(block.timestamp),
                uint32(block.timestamp),
                block.number,
                value
            );
            wolfMapNum[x][y] += 1;
            wolfMap[x][y].push(id);
            wolfOfOwner[to].push(id);
            wolfBalanceOfOwner[to] += 1;
            id2Wolf[id] = wolf;
            aliveWolfs.push(id);
        }
    }

    function genCoordinate(
        int16 _x,
        int16 _y,
        uint32 id
    ) internal returns (int16, int16) {
        uint256 seed = getRomdom();
        // int16 x =seed.toInt16();
        // int16 x = int16(seed);
        // int16 y = int16(seed >> 16);
        return (_x, _y);
    }

    int16 mocked_x;
    int16 mocked_y;
    function genCoordinateMocked() internal returns (int16, int16) {
        int16 _x = mocked_x % 5;
        int16 _y = mocked_y % 5;
        return (_x, _y);
    } 

    function genCoordinateMocked(int16 x, int16 y) internal returns (int16, int16) {
        int16 _x = (mocked_x + x) % 5;
        int16 _y = (mocked_y + y) % 5;
        return (_x, _y);
    } 

    function setGenCoordinateMocked(int16 x, int16 y) external {
        mocked_x = x;
        mocked_y = y;
    }

    function getRomdom() internal returns (uint256) {
        // return block.prevrandao;
        return block.timestamp;
    }

    function updateBlood(
        uint32 blood,
        uint32 operateTime
    ) internal returns (uint32) {
        uint32 diffTime = uint32(block.timestamp) - operateTime;
        return blood > (diffTime / 100) ? (blood - (diffTime / 100)) : 0;
    }

    function updateGrassValue(
        uint256 _value,
        uint32 operateTime
    ) internal view returns (uint256) {
        uint32 diffTime = uint32(block.timestamp) - operateTime;
        uint256 value = _value + diffTime / 1 minutes; //convert to min
        return value;
    }

    function updateSheepValue(
        uint256 _value,
        uint32 operateTime
    ) internal view returns (uint256) {
        uint32 diffTime = uint32(block.timestamp) - operateTime;
        uint256 value = _value + diffTime / 1 minutes; //convert to min
        return value;
    }

    function updateWolfValue(
        uint256 _value,
        uint32 operateTime
    ) internal view returns (uint256) {
        uint32 diffTime = uint32(block.timestamp) - operateTime;
        uint256 value = _value + diffTime / 1 minutes; //convert to min
        return value;
    }

    function updateAssetUniqueId(uint8 species, uint32 id) internal {
        if (species == GRASS_TYPE) {
            globalGrassId = id;
        } else if (species == SHEEP_TYPE) {
            globalSheepId = id;
        } else {
            globalWolfId = id;
        }
    }

    function convert2Sheep(uint256 grassValue) internal returns (uint256) {
        //fixme：小数取整问题
        return (grassValue * 80) / 100;
    }

    function convert2Wolf(uint256 sheepValue) internal returns (uint256) {
        //fixme：小数取整问题
        return (sheepValue * 80) / 100;
    }

    function _getPrice(uint8 species) internal view returns (uint256) {
        if (species == GRASS_TYPE) {
            return grassPrice;
        } else if (species == SHEEP_TYPE) {
            return sheepPrice;
        } else {
            return wolfPrice;
        }
    }

    /*//////////////////////////////////////////////////////////////
                                Views
    //////////////////////////////////////////////////////////////*/
function getSpecieIdsAt(
        uint8 species,
        int16 x,
        int16 y
    ) public view returns (uint32[] memory) {
        if (species == WOLF_TYPE) {
            uint32[] memory wolfs = wolfMap[x][y];
            return wolfs;
        } else if (species == SHEEP_TYPE) {
            uint32[] memory sheeps = sheepMap[x][y];
            return sheeps;
        } else {
            uint32[] memory grasses = grassMap[x][y];
            return grasses;
        }
    }

    function getSpecieNumAt(
        uint8 species,
        int16 x,
        int16 y
    ) public view returns (uint32) {
        if (species == WOLF_TYPE) {
            return wolfMapNum[x][y];
        } else if (species == SHEEP_TYPE) {
            return sheepMapNum[x][y];
        } else {
            return grassMapNum[x][y];
        }
    }

    function getOwnerOfSpecieIds(
        uint8 species,
        address user
    ) external view returns (uint32[] memory) {
        if (species == WOLF_TYPE) {
            return wolfOfOwner[user];
        } else if (species == SHEEP_TYPE) {
            return sheepOfOwner[user];
        } else {
            return grassOfOwner[user];
        }
    }

    function getOwnerOfSpecieNum(
        uint8 species,
        address user
    ) external view returns (uint32) {
        if (species == WOLF_TYPE) {
            return wolfBalanceOfOwner[user];
        } else if (species == SHEEP_TYPE) {
            return sheepBalanceOfOwner[user];
        } else {
            return grassBalanceOfOwner[user];
        }
    }


    function getWolf(uint32 id) external view returns (int16, int16, address, uint32, uint32, uint32, uint32, uint256, uint256) {
        Wolf memory wolf = id2Wolf[id];
        return (wolf.x, wolf.y, wolf.owner, wolf.id, wolf.blood, wolf.bornTime, wolf.updateTime, wolf.height, wolf.value);
    }

    function getSheep(uint32 id) external view returns (int16, int16, address, uint32, uint32, uint32, uint32, uint256, uint256) {
        Sheep memory sheep = id2Sheep[id];
        return (sheep.x, sheep.y, sheep.owner, sheep.id, sheep.blood, sheep.bornTime, sheep.updateTime, sheep.height ,sheep.value);
    }

    function getGrass(uint32 id) external view returns (int16, int16, address, uint32, uint32, uint32, uint256, uint256) {
        Grass memory grass = id2Grass[id];
        return (grass.x, grass.y, grass.owner, grass.id, grass.bornTime, grass.updateTime, grass.height, grass.value);
    }
}
