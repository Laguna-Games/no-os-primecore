// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
// forge-ignore: 5574

import {console} from '../../lib/forge-std/src/console.sol';
import {IDiamondCut} from '../../lib/laguna-diamond-foundry/src/interfaces/IDiamondCut.sol';
import {LibDeploy} from '../../lib/laguna-diamond-foundry/script/util/LibDeploy.s.sol';
import {DN404Facet} from '../../src/facets/DN404Facet.sol';

library DN404FacetDeployLib {
    string public constant FACET_NAME = 'DN404Facet';

    /// @notice Returns the list of public selectors belonging to the DN404Facet
    /// @return selectors List of selectors
    function getSelectorList() internal pure returns (bytes4[] memory selectors) {
        selectors = new bytes4[](20);
        selectors[0] = DN404Facet.totalSupply.selector;
        selectors[1] = DN404Facet.balanceOf.selector;
        selectors[2] = DN404Facet.allowance.selector;
        selectors[3] = DN404Facet.approve.selector;
        selectors[4] = DN404Facet.transfer.selector;
        selectors[5] = DN404Facet.transferFrom.selector;
        selectors[6] = DN404Facet.getSkipNFT.selector;
        selectors[7] = DN404Facet.setSkipNFT.selector;
        selectors[8] = DN404Facet.mirrorERC721.selector;
        selectors[9] = DN404Facet.transferFromNFT.selector;
        selectors[10] = DN404Facet.setApprovalForAllNFT.selector;
        selectors[11] = DN404Facet.isApprovedForAllNFT.selector;
        selectors[12] = DN404Facet.ownerOfNFT.selector;
        selectors[13] = DN404Facet.ownerAtNFT.selector;
        selectors[14] = DN404Facet.approveNFT.selector;
        selectors[15] = DN404Facet.getApprovedNFT.selector;
        selectors[16] = DN404Facet.balanceOfNFT.selector;
        selectors[17] = DN404Facet.totalNFTSupply.selector;
        selectors[18] = DN404Facet.tokenOfNFTOwnerByIndex.selector;
        selectors[19] = DN404Facet.reroll.selector;
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
        facet = address(new DN404Facet());
        console.log(string.concat(string.concat('Deployed ', FACET_NAME, ' at: ', LibDeploy.getVM().toString(facet))));
    }

    /// @notice Attaches a DN404Facet to a diamond
    function attachFacetToDiamond(address diamond, address facet) internal {
        LibDeploy.cutFacetOntoDiamond(FACET_NAME, generateFacetCut(facet), diamond);
    }

    /// @notice Removes the DN404Facet from a Diamond
    /// @dev NOTE: This is a greedy cleanup - use it to nuke all of an old facet (even if the old version has extra
    /// deprecated endpoints). If you are un-sure please review this code carefully before using it!
    function removeFacetFromDiamond(address diamond) internal {
        LibDeploy.cutFacetOffOfDiamond(FACET_NAME, getSelectorList(), diamond);
    }
}
