// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
// forge-ignore: 5574

import {console} from '../../lib/forge-std/src/console.sol';
import {IDiamondCut} from '../../lib/laguna-diamond-foundry/src/interfaces/IDiamondCut.sol';
import {LibDeploy} from '../../lib/laguna-diamond-foundry/script/util/LibDeploy.s.sol';
import {DN404MetadataFacet} from '../../src/facets/DN404MetadataFacet.sol';

library DN404MetadataFacetDeployLib {
    string public constant FACET_NAME = 'DN404MetadataFacet';

    /// @notice Returns the list of public selectors belonging to the DN404MetadataFacet
    /// @return selectors List of selectors
    function getSelectorList() internal pure returns (bytes4[] memory selectors) {
        selectors = new bytes4[](8);
        selectors[0] = DN404MetadataFacet.name.selector;
        selectors[1] = DN404MetadataFacet.symbol.selector;
        selectors[2] = DN404MetadataFacet.decimals.selector;
        selectors[3] = DN404MetadataFacet.tokenURINFT.selector;
        selectors[4] = DN404MetadataFacet.baseURI.selector;
        selectors[5] = DN404MetadataFacet.getImageURI.selector;
        selectors[6] = DN404MetadataFacet.contractURI.selector;
        selectors[7] = DN404MetadataFacet.tokenURI.selector;
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
        facet = address(new DN404MetadataFacet());
        console.log(string.concat(string.concat('Deployed ', FACET_NAME, ' at: ', LibDeploy.getVM().toString(facet))));
    }

    /// @notice Attaches a DN404MetadataFacet to a diamond
    function attachFacetToDiamond(address diamond, address facet) internal {
        LibDeploy.cutFacetOntoDiamond(FACET_NAME, generateFacetCut(facet), diamond);
    }

    /// @notice Removes the DN404MetadataFacet from a Diamond
    /// @dev NOTE: This is a greedy cleanup - use it to nuke all of an old facet (even if the old version has extra
    /// deprecated endpoints). If you are un-sure please review this code carefully before using it!
    function removeFacetFromDiamond(address diamond) internal {
        LibDeploy.cutFacetOffOfDiamond(FACET_NAME, getSelectorList(), diamond);
    }
}
