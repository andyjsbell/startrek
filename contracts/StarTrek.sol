// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract StarTrek {
    struct Time {
        uint timeStart;
        uint timeUp;
    }
    struct Enterprise {
        bool docked;
        uint16 energy;
        uint8 torps;
        uint shield;
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
    uint8 constant Q_SPACE = 0;
    uint8 constant Q_STAR = 1;
    uint8 constant Q_BASE = 2;
    uint8 constant Q_KLINGON = 3;
    uint8 constant Q_SHIP = 4;

    uint randomNonce = 0;
    uint starDate;
    Time starTime;
    Enterprise enterprise;
    uint16[9][9] galaxy;
    uint8[8][8] quadrant;
    uint totalKlingons;
    Klingon[3] klingonData;
    uint16 damage;
    uint8 baseY;
    uint8 baseX;

    event GameInitialised(uint klingons, Time time, uint starbases);
    event StartQuadrant(string name);
    event EnterQuadrant(string name);
    event ConditionRed();
    event ShieldsDangerouslyLow();

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
    }

    function resignCommission() public {}

    function libraryComputer() public {}

    function damageControl() public {}

    function shieldControl() public {}

    function photonTorpedoes() public {}

    function phaserControl() public {}

    function courseControl() public {}

    function longRangeScan() public {}

    function randomMod(uint _modulus) internal returns (uint) {
        randomNonce++;
        return
            uint(
                keccak256(
                    abi.encodePacked(block.timestamp, msg.sender, randomNonce)
                )
            ) % _modulus;
    }

    function initializeEnterprise() internal {
        enterprise.docked = false;
        enterprise.energy = 3000;
        enterprise.torps = 10;
        enterprise.shield = 0;
        enterprise.quadY = uint8(randomMod(8));
        enterprise.quadX = uint8(randomMod(8));
        enterprise.shipY = uint8(randomMod(8));
        enterprise.shipX = uint8(randomMod(8));
        for (uint8 i = 1; i <= 8; i++) {
            enterprise.damage[i] = 0;
        }
    }

    function initialize() public {
        uint8 yp;
        uint8 xp;
        starTime.timeStart = starDate;
        starTime.timeUp = INITIAL_TIMEUP + randomMod(10);
        initializeEnterprise();
        uint8 klingonsLeft = 0;
        uint8 starbasesLeft = 0;

        for (uint8 i = 1; i <= 8; i++) {
            for (uint8 j = 1; j <= 8; j++) {
                uint8 r = uint8(randomMod(100));
                uint8 klingons = 0;
                if (r > 98) klingons = 3;
                else if (r > 95) klingons = 2;
                else if (r > 80) klingons = 1;

                klingonsLeft += klingons;
                uint8 starbases = 0;

                if (uint8(randomMod(100)) > 96) starbases = 1;

                starbasesLeft += starbases;

                galaxy[i][j] =
                    (klingons << 8) +
                    (starbases << 4) +
                    uint8(randomMod(8));
            }
        }

        // Give more time for more Klingons
        if (klingonsLeft > starTime.timeUp) starTime.timeUp = klingonsLeft + 1;

        /* Add a base if we don't have one */
        if (starbasesLeft == 0) {
            yp = uint8(randomMod(8));
            xp = uint8(randomMod(8));
            if (galaxy[yp][xp] < 0x200) {
                galaxy[yp][xp] += (uint8(1) << 8);
                klingonsLeft++;
            }

            galaxy[yp][xp] += (1 << 4);
            starbasesLeft++;
        }

        totalKlingons = klingonsLeft;

        emit GameInitialised(totalKlingons, starTime, starbasesLeft);
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
                x = x - 4;
            }
            quadName = string.concat(quadName, sectionNames[x]);
        }

        return quadName;
    }

    function placeShip() internal {
        quadrant[enterprise.shipY - 1][enterprise.shipX - 1] = Q_SHIP;
    }

    function findSetEmptyPlace(uint8 t) internal returns (uint8, uint8) {
        uint8 r1;
        uint8 r2;
        do {
            r1 = uint8(randomMod(8));
            r2 = uint8(randomMod(8));
        } while (quadrant[r1 - 1][r2 - 1] != Q_SPACE);

        quadrant[r1 - 1][r2 - 1] = t;

        return (r1, r2);
    }

    function newQuadrant() public {
        damage = uint16(randomMod(50)) - 1;
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

        uint16 quad = galaxy[enterprise.quadY][enterprise.quadX];
        uint8 klingons = uint8((quad >> 8)) & 0x0F;
        uint8 starbases = uint8((quad >> 4)) & 0x0F;
        uint8 stars = uint8(quad) & 0x0F;
        if (klingons > 0) {
            emit ConditionRed();
            if (enterprise.shield < 200) {
                emit ShieldsDangerouslyLow();
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
                (uint8 y, uint8 x) = findSetEmptyPlace(Q_KLINGON);
                klingonData[i].y = y;
                klingonData[i].x = x;
                klingonData[i].energy = uint16(100) + uint16(randomMod(200));
            }
        }
        if (starbases > 0) {
            (uint8 y, uint8 x) = findSetEmptyPlace(Q_BASE);
            baseY = y;
            baseX = x;
        }

        for (uint8 i = 1; i <= stars; i++) {
            findSetEmptyPlace(Q_STAR);
        }
    }

    function shortRangeScan() public {}
}
