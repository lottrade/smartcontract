// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITokenSale {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    function percentUnlocked() external view returns(uint8);
    
    function maxPosibilityUnlocked() external view returns(uint256);
    
    function posibilityUnlocked() external view returns(uint256);
    
    function getLockedWallets() external view returns(address[] memory, uint256[] memory);
    
    function getUnlockedTableTime() external view returns(uint8[] memory, uint8[] memory);
    
    function lockedForOwner(address _to, uint256 _amountBUSD) external;
    
    function locked(uint256 _amountBUSD) external;
    
    function unlocked(uint256 _amount) external;
}


contract TokenSaleRouter {
    function balanceOf(address contractAddress, address account)
        external
        view
        returns (uint256)
    {
        return ITokenSale(contractAddress).balanceOf(account);
    }
    
    function percentUnlocked(address contractAddress) external view returns(uint8) {
        return ITokenSale(contractAddress).percentUnlocked();
    }
    
    function maxPosibilityUnlocked(address contractAddress) external view returns(uint256) {
        return ITokenSale(contractAddress).maxPosibilityUnlocked();
    }
    
    function posibilityUnlocked(address contractAddress) external view returns(uint256) {
        return ITokenSale(contractAddress).posibilityUnlocked();
    }
    
    function lockedWallets(address contractAddress) external view returns(address[] memory, uint256[] memory) {
        return ITokenSale(contractAddress).getLockedWallets();
    }
    
    function unlockedTableTime(address contractAddress) external view returns(uint8[] memory, uint8[] memory) {
        return ITokenSale(contractAddress).getUnlockedTableTime();
    }
    
    function lockedForOwner(address contractAddress, address _to, uint256 _amountBUSD) external {
        ITokenSale(contractAddress).lockedForOwner(_to, _amountBUSD);
    }
    
    function locked(address contractAddress, uint256 _amountBUSD) external {
        ITokenSale(contractAddress).locked(_amountBUSD);
    }
    
    function unlocked(address contractAddress, uint256 _amount) external {
        ITokenSale(contractAddress).unlocked(_amount);
    }
}
