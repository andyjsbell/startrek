// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library Utils {}

contract StarTrek {
    struct Time {
        uint timeStart;
        uint timeUp;
    }

    struct Enterprise {
        bool docked;
        uint16 energy;
        uint8 torps;
        uint8 shield;
        uint8 quadY;
        uint8 quadX;
        uint16 shipX;
        uint16 shipY;
        uint16[9] damage;
    }

    struct Klingon {
        uint8 y;
        uint8 x;
        uint16 energy;
    }

    struct Coord {
        uint8 x;
        uint8 y;
    }

    enum Command {
        NAV,
        SRS,
        LRS,
        PHA,
        TOR,
        SHI,
        DAM,
        COM,
        XXX
    }

    uint constant INITIAL_TIMEUP = 25;
    uint16 constant MAP_VISITED = 0x1000;
    // TODO Enum here
    uint8 constant Q_SPACE = 0;
    uint8 constant Q_STAR = 1;
    uint8 constant Q_BASE = 2;
    uint8 constant Q_KLINGON = 3;
    uint8 constant Q_SHIP = 4;

    // Nonce for pseudo random generator
    uint randomNonce = 0;
    // Incrementing star date
    uint starDate;
    // Star time
    Time starTime;
    // Our home
    Enterprise enterprise;
    // Galaxy, not as quite as big as one thinks.  Made up of 9x9 quadrants
    uint16[9][9] galaxy;
    // A quadrant of a galaxy which has 8x8 cells
    uint8[8][8] quadrant;

    uint8 totalKlingons;
    Klingon[3] klingonData;
    uint8 baseY;
    uint8 baseX;

    // Events
    event GameInitialised(uint8 klingons, Time time, uint8 starbases);
    event StartQuadrant(string name);
    event EnterQuadrant(string name);
    event ConditionRed(uint8 klingons);
    event ShieldsDangerouslyLow(uint8 klingons, uint8 shield);

    function newGame() public {
        initialize();
        newQuadrant();
        shortRangeScan();
        // Game proceeds by transacting with `runCommand` - all the best of luck!
    }

    function compareString(
        bytes32 _string1,
        bytes32 _string2
    ) internal pure returns (bool) {
        return
            keccak256(abi.encodePacked(_string1)) ==
            keccak256(abi.encodePacked(_string2));
    }

    function runCommand(Command _command) public {
        if (_command == Command.NAV) {
            courseControl();
        } else if (_command == Command.SRS) {
            shortRangeScan();
        } else if (_command == Command.LRS) {
            longRangeScan();
        } else if (_command == Command.PHA) {
            phaserControl();
        } else if (_command == Command.PHA) {
            photonTorpedoes();
        } else if (_command == Command.SHI) {
            shieldControl();
        } else if (_command == Command.DAM) {
            damageControl();
        } else if (_command == Command.COM) {
            libraryComputer();
        } else if (_command == Command.XXX) {
            resignCommission();
        }

        // Everybody contributes to the housekeeping of the game
        houseKeeping();
    }

    function houseKeeping() internal {}

    function resignCommission() internal {}

    function libraryComputer() internal {}

    function damageControl() internal {}

    function shieldControl() internal {}

    function photonTorpedoes() internal {}

    function phaserControl() internal {}

    function courseControl() internal {}

    function longRangeScan() internal {}

    function randomMod(uint _modulus) internal returns (uint) {
        randomNonce++;
        return
            uint(
                keccak256(
                    abi.encodePacked(block.timestamp, msg.sender, randomNonce)
                )
            ) % _modulus;
    }

    function randomUInt8(uint8 modulus) internal returns (uint8) {
        return uint8(randomMod(modulus));
    }

    function initializeEnterprise(Enterprise storage _enterprise) internal {
        _enterprise.docked = false;
        _enterprise.energy = 3000;
        _enterprise.torps = 10;
        _enterprise.shield = 0;
        _enterprise.quadY = randomUInt8(8);
        _enterprise.quadX = randomUInt8(8);
        _enterprise.shipY = randomUInt8(8);
        _enterprise.shipX = randomUInt8(8);
        _enterprise.damage = [0, 0, 0, 0, 0, 0, 0, 0];
    }

    function initializeTime(Time storage _time) internal {
        _time.timeStart = starDate;
        _time.timeUp = INITIAL_TIMEUP + randomMod(10);
    }

    function initialize() public {
        initializeTime(starTime);
        initializeEnterprise(enterprise);

        uint8 numberOfKlingons = 0;
        uint8 numberOfStarBases = 0;

        for (uint8 i = 1; i <= 8; i++) {
            for (uint8 j = 1; j <= 8; j++) {
                uint8 r = randomUInt8(100);
                uint8 klingons = 0;
                if (r > 98) { 
                    klingons = 3;
                }
                else if (r > 95) {
                    klingons = 2;
                }
                else if (r > 80) {
                    klingons = 1;
                }

                numberOfKlingons += klingons;
                uint8 starbases = 0;

                if (randomUInt8(100) > 96) {
                    starbases = 1;
                    numberOfStarBases += starbases;
                }
                
                galaxy[i][j] = encodeQuadrant(
                    klingons,
                    starbases,
                    randomUInt8(8)
                );
            }
        }

        // Give more time for more Klingons
        if (numberOfKlingons > starTime.timeUp) {
            starTime.timeUp = numberOfKlingons + 1;
        }

        /* Add a base if we don't have one */
        if (numberOfStarBases == 0) {
            uint y = randomUInt8(8);
            uint x = randomUInt8(8);
            if (galaxy[y][x] < 0x200) {
                galaxy[y][x] += (uint8(1) << 8);
                numberOfKlingons++;
            }

            galaxy[y][x] += (1 << 4);
            numberOfStarBases++;
        }

        totalKlingons = numberOfKlingons;

        emit GameInitialised(totalKlingons, starTime, numberOfStarBases);
    }

    function quadrantName(
        bool small,
        uint8 y,
        uint8 x
    ) internal pure returns (string memory) {
        string[17] memory quadNames = [
            "",
            "Antares",
            "Rigel",
            "Procyon",
            "Vega",
            "Canopus",
            "Altair",
            "Sagittarius",
            "Pollux",
            "Sirius",
            "Deneb",
            "Capella",
            "Betelgeuse",
            "Aldebaran",
            "Regulus",
            "Arcturus",
            "Spica"
        ];
        string[5] memory sectionNames = ["", " I", " II", " III", " IV"];

        if (y < 1 || y > 8 || x < 1 || x > 8) {
            return "Unknown";
        }

        string memory quadName;
        if (x <= 4) {
            quadName = quadNames[y];
        } else {
            quadName = quadNames[y + 8];
        }

        if (small) {
            if (x > 4) {
                x -= 4;
            }
            quadName = string.concat(quadName, sectionNames[x]);
        }

        return quadName;
    }

    function placeShip() internal {
        quadrant[enterprise.shipY - 1][enterprise.shipX - 1] = Q_SHIP;
    }

    function findEmptyCoordinate() internal returns (bool, Coord memory) {
        Coord[] memory emptySpaces;
        uint8 numberOfEmptySpaces = 0;

        for (uint8 i = 0; i < 8; i++) {
            for (uint8 j = 0; j < 8; j++) {
                if (quadrant[i][j] == Q_SPACE) {
                    Coord memory coord;
                    coord.y = i;
                    coord.x = j;
                    emptySpaces[numberOfEmptySpaces++] = coord;
                }
            }
        }

        if (numberOfEmptySpaces > 0) {
            return (true, emptySpaces[randomMod(numberOfEmptySpaces) - 1]);
        }

        return (false, Coord(0, 0));
    }

    function decodeQuadrant(
        Coord memory coord
    ) internal view returns (uint8, uint8, uint8) {
        uint16 quad = galaxy[coord.y][coord.x];
        return (
            uint8((quad >> 8)) & 0x0F,
            uint8((quad >> 4)) & 0x0F,
            uint8(quad) & 0x0F
        );
    }

    function encodeQuadrant(
        uint8 klingons,
        uint8 starbases,
        uint8 stars
    ) internal pure returns (uint16) {
        return (klingons << 8) + (starbases << 4) + stars;
    }

    function newQuadrant() internal {
        galaxy[enterprise.quadY][enterprise.quadX] |= MAP_VISITED;
        if (
            enterprise.quadY >= 1 &&
            enterprise.quadY <= 8 &&
            enterprise.quadX >= 1 &&
            enterprise.quadX <= 8
        ) {
            string memory name = quadrantName(
                false,
                enterprise.quadY,
                enterprise.quadX
            );
            if (starTime.timeStart != starDate) {
                emit EnterQuadrant(name);
            } else {
                emit StartQuadrant(name);
            }
        }

        (uint8 klingons, uint8 starbases, uint8 stars) = decodeQuadrant(
            Coord(enterprise.quadY, enterprise.quadX)
        );

        if (klingons > 0) {
            emit ConditionRed(klingons);
            if (enterprise.shield < 200) {
                emit ShieldsDangerouslyLow(klingons, enterprise.shield);
            }
        }

        for (uint8 i = 1; i <= 3; i++) {
            klingonData[i].y = 0;
            klingonData[i].x = 0;
            klingonData[i].energy = 0;
        }

        for (uint i = 0; i < 8; i++) {
            for (uint j = 0; j < 8; j++) {
                quadrant[i][j] = Q_SPACE;
            }
        }

        placeShip();

        if (klingons > 0) {
            for (uint i = 0; i < klingons; i++) {
                (bool empty, Coord memory coord) = findEmptyCoordinate();
                if (empty) {
                    quadrant[coord.y][coord.x] = Q_KLINGON;
                    klingonData[i].y = coord.y;
                    klingonData[i].x = coord.x;
                    klingonData[i].energy =
                        uint16(100) +
                        uint16(randomMod(200));
                }
            }
        }

        if (starbases > 0) {
            (bool empty, Coord memory coord) = findEmptyCoordinate();
            if (empty) {
                quadrant[coord.y][coord.x] = Q_BASE;
                baseY = coord.y;
                baseX = coord.x;
            }
        }

        for (uint8 i = 1; i <= stars; i++) {
            (bool empty, Coord memory coord) = findEmptyCoordinate();
            if (empty) {
                quadrant[coord.y][coord.x] = Q_STAR;
            }
        }
    }

    function shortRangeScan() public {}
}
