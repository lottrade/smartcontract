// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ITokenSale {
    function balanceOf(address account) external view returns (uint256);
    
    function getUnlockedTableTime() external view returns(uint8[] memory, uint8[] memory);
}


contract TokenSaleRouter {
    function balanceOf(address contractAddress, address account)
        external
        view
        returns (uint256)
    {
        return ITokenSale(contractAddress).balanceOf(account);
    }
    
    function unlockedTableTime(address contractAddress) external view returns(uint8[] memory, uint8[] memory) {
        return ITokenSale(contractAddress).getUnlockedTableTime();
    }
}
