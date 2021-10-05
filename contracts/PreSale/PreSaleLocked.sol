// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./PreSaleBase.sol";
import "../utils/safemath.sol";
import "../utils/address.sol";

contract PreSaleLocked is PreSaleBase {
    using SafeMath for uint256;
    using Address for address;
    
    struct LockedWallets {
        address owner;
        uint256 locked;
    }
    
    modifier validateLocked(uint256 _amountBUSD) {
        uint256 amoutLott = _amountBUSD.div(_lottPrice).mul(10 ** 18);
        require(block.timestamp > _startDate && block.timestamp < _finishDate, "PreSale::locked: PreSale already finished");
        require(_maxCap > 0 && _maxCap >= amoutLott, "PreSale::locked: PreSale already finished");
        require(amoutLott >= _minPurchase, "PreSale::locked: Amount less than minimum purchase");
        uint preSaleLottBalance = LOTT.balanceOf(address(this));
        require(preSaleLottBalance >= amoutLott, "PreSale::locked: Amount more than pre sale LOTT balance");
        _;
    }
    
    function balanceOf(address _owner) external view returns(uint256) {
        return lockedBalances[_owner];
    }
    
    function setLottContractAddress(address _address) external onlyOwner {
        require(_address.isContract(), "PreSale::setLottContractAddress: Address must be contract address");
        LOTT = IERC20(_address);
    }
    
    function setBUSDContractAddress(address _address) external onlyOwner {
        require(_address.isContract(), "PreSale::setBUSDContractAddress: Address must be contract address");
        BUSD = IERC20(_address);
    }
    
    function _locked(address _to, uint256 _amountLOTT) private {
        uint256 amountBUSD = _amountLOTT.mul(_lottPrice).div(10 ** 18);
        BUSD.transferFrom(msg.sender, address(this), amountBUSD);
        _maxCap -= _amountLOTT;
        lockedBalances[_to] += _amountLOTT;
        _lockedBalances[_to] += _amountLOTT;
        _lockedWallets.push(_to);
        emit Locked(_to, _amountLOTT);
    }
    
    function _lockedForOwner(address _to, uint256 _amountLOTT) private {
        _maxCap -= _amountLOTT;
        lockedBalances[_to] += _amountLOTT;
        _lockedBalances[_to] += _amountLOTT;
        _lockedWallets.push(_to);
        emit Locked(_to, _amountLOTT);
    }
    
    function locked(uint256 _amountBUSD) external validateLocked(_amountBUSD) {
        uint256 amoutLott = _amountBUSD.div(_lottPrice).mul(10 ** 18);
        _locked(msg.sender, amoutLott);
    }
    
    function lockedForOwner(address _to, uint256 _amountBUSD) external onlyOwner validateLocked(_amountBUSD) {
        require(!_to.isContract(), "PreSale::lockedForOwner: To address must not be contract address");
        require(_to != address(0), "PreSale::lockedForOwner: To address is zero.");
        uint256 amoutLott = _amountBUSD.div(_lottPrice).mul(10 ** 18);
        _lockedForOwner(_to, amoutLott);
    }
    
    function getLockedWallets() external view onlyOwner returns (LockedWallets[] memory) {
        LockedWallets[] memory result = new LockedWallets[](_lockedWallets.length);
        for (uint i = 0; i < _lockedWallets.length; i++) {
            address item = _lockedWallets[i];
            uint256 balance = lockedBalances[item];
            if (lockedBalances[item] > 0) {
                result[i] = LockedWallets(item, balance);
            }
        }
        
        return result;
    }
}