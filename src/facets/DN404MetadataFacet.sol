// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LibTokenURI} from '../libraries/LibTokenURI.sol';
import {LibDN404} from '../libraries/LibDN404.sol';

contract DN404MetadataFacet {
    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*               METADATA FUNCTIONS                           */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @dev Returns the name of the token.
    function name() public view returns (string memory) {
        return LibDN404._getDN404Storage().name;
    }

    /// @dev Returns the symbol of the token.
    function symbol() public view returns (string memory) {
        return LibDN404._getDN404Storage().symbol;
    }

    /// @dev Returns the decimals places of the token. Defaults to 18.
    function decimals() public pure returns (uint8) {
        return LibDN404._decimals();
    }

    /// @dev Returns the tokenURI of the token.
    function tokenURINFT(uint256 id) public view returns (string memory) {
        return LibTokenURI.generateTokenURI(uint32(id));
    }
}
