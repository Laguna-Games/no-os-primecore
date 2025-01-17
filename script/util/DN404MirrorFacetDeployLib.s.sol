// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
// forge-ignore: 5574

import {console} from '../../lib/forge-std/src/console.sol';
import {IDiamondCut} from '../../lib/laguna-diamond-foundry/src/interfaces/IDiamondCut.sol';
import {LibDeploy} from '../../lib/laguna-diamond-foundry/script/util/LibDeploy.s.sol';
import {DN404MirrorFacet} from '../../src/facets/DN404MirrorFacet.sol';

library DN404MirrorFacetDeployLib {
    string public constant FACET_NAME = 'DN404MetadataFacet';

    /// @notice Returns the list of public selectors belonging to the DN404MirrorFacet
    /// @return selectors List of selectors
    function getSelectorList() internal pure returns (bytes4[] memory selectors) {
        selectors = new bytes4[](21);
        selectors[0] = DN404MirrorFacet.name.selector;
        selectors[1] = DN404MirrorFacet.symbol.selector;
        selectors[2] = DN404MirrorFacet.tokenURI.selector;
        selectors[3] = DN404MirrorFacet.totalSupply.selector;
        selectors[4] = DN404MirrorFacet.balanceOf.selector;
        selectors[5] = DN404MirrorFacet.ownerOf.selector;
        selectors[6] = DN404MirrorFacet.ownerAt.selector;
        selectors[7] = DN404MirrorFacet.approve.selector;
        selectors[8] = DN404MirrorFacet.getApproved.selector;
        selectors[9] = DN404MirrorFacet.setApprovalForAll.selector;
        selectors[10] = DN404MirrorFacet.isApprovedForAll.selector;
        selectors[11] = DN404MirrorFacet.transferFrom.selector;
        selectors[12] = 0x42842e0e; // safeTransferFrom
        selectors[13] = 0xb88d4fde; // safeTransferFrom
        selectors[14] = DN404MirrorFacet.tokenOfOwnerByIndex.selector;
        selectors[15] = DN404MirrorFacet.getUserTokensBatch.selector;
        selectors[16] = DN404MirrorFacet.pullOwner.selector;
        selectors[17] = DN404MirrorFacet.baseERC20.selector;
        selectors[18] = DN404MirrorFacet.logTransfer.selector;
        selectors[19] = DN404MirrorFacet.logDirectTransfer.selector;
        selectors[20] = DN404MirrorFacet.linkMirrorContract.selector;
    }

    /// @notice Creates a FacetCut object for attaching a facet to a Diamond
    /// @dev This method is exposed to allow multiple cuts to be bundled in one call
    /// @param facet The address of the facet to attach
    /// @return cut The `Add` FacetCut object
    function generateFacetCut(address facet) internal pure returns (IDiamondCut.FacetCut memory cut) {
        cut = LibDeploy.facetCutGenerator(facet, getSelectorList());
    }

    /// @notice Deploys a new facet instance
    /// @return facet The address of the deployed facet
    function deployNewInstance() internal returns (address facet) {
        facet = address(new DN404MirrorFacet());
        console.log(string.concat(string.concat('Deployed ', FACET_NAME, ' at: ', LibDeploy.getVM().toString(facet))));
    }

    /// @notice Attaches a DN404MirrorFacet to a diamond
    function attachFacetToDiamond(address diamond, address facet) internal {
        LibDeploy.cutFacetOntoDiamond(FACET_NAME, generateFacetCut(facet), diamond);
    }

    /// @notice Removes the DN404MirrorFacet from a Diamond
    /// @dev NOTE: This is a greedy cleanup - use it to nuke all of an old facet (even if the old version has extra
    /// deprecated endpoints). If you are un-sure please review this code carefully before using it!
    function removeFacetFromDiamond(address diamond) internal {
        LibDeploy.cutFacetOffOfDiamond(FACET_NAME, getSelectorList(), diamond);
    }
}
