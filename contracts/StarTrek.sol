// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract StarTrek {
    struct Time {
        uint timeStart;
        uint timeUp;
    }
    struct Enterprise {
        bool docked;
        uint energy;
        uint8 torps;
        uint shield;
        uint8 quadY;
        uint8 quadX;
        uint16 shipX;
        uint16 shipY;
        uint16[9] damage;
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
    uint randomNonce = 0;
    uint starDate;
    Time starTime;
    Enterprise enterprise;
    uint[9][9] galaxy;
    uint totalKlingons;

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
        uint8 klingons_left = 0;
        uint8 starbases_left = 0;

        for (uint8 i = 1; i <= 8; i++) {
            for (uint8 j = 1; j <= 8; j++) {
                uint8 r = uint8(randomMod(100));
                uint8 klingons = 0;
                if (r > 98) klingons = 3;
                else if (r > 95) klingons = 2;
                else if (r > 80) klingons = 1;

                klingons_left = klingons_left + klingons;
                uint8 starbases = 0;

                if (uint8(randomMod(100)) > 96) starbases = 1;

                starbases_left = starbases_left + starbases;

                galaxy[i][j] =
                    (klingons << 8) +
                    (starbases << 4) +
                    randomMod(8);
            }
        }

        // Give more time for more Klingons
        if (klingons_left > starTime.timeUp)
            starTime.timeUp = klingons_left + 1;

        /* Add a base if we don't have one */
        if (starbases_left == 0) {
            yp = uint8(randomMod(8));
            xp = uint8(randomMod(8));
            if (galaxy[yp][xp] < 0x200) {
                galaxy[yp][xp] += (1 << 8);
                klingons_left++;
            }

            galaxy[yp][xp] += (1 << 4);
            starbases_left++;
        }

        totalKlingons = klingons_left;
    }

    function newQuadrant() public {}

    function shortRangeScan() public {}
}
