// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./TokenSaleLocked.sol";

contract TokenSaleUnlocked is TokenSaleLocked {
    modifier checkUnlocked() {
        UnlockedTable
            memory firstMonthUnlockedTable = _firstMonthUnlockedTable();

        uint256 firstTimeLocked = _lockedBalancesFirstTime[tx.origin];
        require(firstTimeLocked > 0 && block.timestamp > firstTimeLocked, "TokenSale::unlocked: Unlocked is not active");

        require(
            block.timestamp >
                firstTimeLocked +
                    (firstMonthUnlockedTable.month * _daysInMonth),
            "TokenSale::unlocked: Unlocked is not active"
        );
        _;
    }

    function _firstMonthUnlockedTable()
        private
        view
        returns (UnlockedTable memory)
    {
        uint8 checkMinMonth = _unlockedMonths[0];
        uint8 checkMinMonthIndex = 0;
        for (uint8 i = 0; i < _unlockedMonths.length; i++) {
            if (
                checkMinMonth > _unlockedMonths[i] && _unlockedPercents[i] > 0
            ) {
                checkMinMonth = _unlockedMonths[i];
                checkMinMonthIndex = i;
            }
        }

        return
            UnlockedTable(_unlockedPercents[checkMinMonthIndex], checkMinMonth);
    }

    constructor(address _busd, address _lott, uint256 _maxCap, uint256 _lottPrice, uint8[] memory _percents, uint8[] memory _months) {
        LOTT = IERC20(_lott);
        BUSD = IERC20(_busd);
        _setMaxCap(_maxCap);
        _setLottPrice(_lottPrice);
        _setUnlockedTable(_percents, _months);
    }

    function _unlocked(uint256 _amount) internal {
        LOTT.transfer(tx.origin, _amount);
        lockedBalances[tx.origin] -= _amount;
        emit UnLocked(tx.origin, _amount);
    }

    function unlocked(uint256 _amount) external checkUnlocked {
        uint256 maxPosUnlocked = _calculateMaxPosibilityUnlocked();
        require(
            maxPosUnlocked >= _amount,
            "TokenSale::unlocked: Amount more than max posibility unlocked"
        );
        require(
            (_lockedBalances[tx.origin] - lockedBalances[tx.origin]) +
                _amount <=
                maxPosUnlocked,
            "TokenSale::unlocked: Amount more than posibility unlocked"
        );
        uint256 actualBalanceLOTT = LOTT.balanceOf(address(this));
        require(
            actualBalanceLOTT >= _amount,
            "TokenSale::unlocked: Contract does not have enough money to unlock"
        );
        _unlocked(_amount);
    }
    
    function _calculateMaxPosibilityUnlocked() internal view returns(uint256) {
        uint32 percent = _percentUnlocked();
        
        return  (percent * _lockedBalances[tx.origin]) / 100;
    }

    function _percentUnlocked() private view returns (uint8) {
        uint8 percent;
        uint8 maxPercent = 100;
        uint256 timeNow = block.timestamp;
        uint256 firstTimeLocked = _lockedBalancesFirstTime[tx.origin];

        uint8 calcPercent = 0;
        bool checkLastMonth = false;
        uint8 lastPercent;
        uint8 lastMonth;
        for (uint8 i = 0; i < _unlockedMonths.length; i++) {
            uint8 unLockedMonth = _unlockedMonths[i];
            uint8 unLockedPercent = _unlockedPercents[i];
            if (
                unLockedPercent > 0 &&
                timeNow >
                firstTimeLocked + (unLockedMonth * _daysInMonth)
            ) {
                calcPercent += unLockedPercent;
                if (i == _unlockedMonths.length - 1) {
                    checkLastMonth = true;
                    lastPercent = unLockedPercent;
                    lastMonth = unLockedMonth;
                }
            }
        }

        if (checkLastMonth && calcPercent < maxPercent) {
            uint8 calcMissingMonth = (maxPercent - calcPercent) / lastPercent;
            for (uint8 i = 1; i <= calcMissingMonth; i++) {
                uint8 nextMonth = lastMonth + i;
                if (timeNow > firstTimeLocked + (nextMonth * _daysInMonth)) {
                    calcPercent += lastPercent;
                }
            }
        }

        percent = calcPercent;

        return percent;
    }
    
    function percentUnlocked() external view checkUnlocked returns(uint8) {
        return _percentUnlocked();
    }
    
    function maxPosibilityUnlocked() external view checkUnlocked returns(uint256) {
        return _calculateMaxPosibilityUnlocked();
    }
    
    function posibilityUnlocked() external view checkUnlocked returns(uint256) {
        if (lockedBalances[tx.origin] > 0) {
            return _calculateMaxPosibilityUnlocked() - (_lockedBalances[tx.origin] - lockedBalances[tx.origin]);
        }
        
        return _calculateMaxPosibilityUnlocked();
    }
}
