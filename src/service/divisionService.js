import _ from 'lodash';
import { ServerError, ApiError } from 'Errors';
import DivisionRepo from '../repository/division';
import { DivisionManager } from 'Managers';
import {
    DIVISION_NOT_FOUND_CODE,
} from '../errors/ErrorCodes';
import {HTTP_CODE_404,HTTP_CODE_201,HTTP_CODE_200} from '../routes/constants/HttpCodes';
const uuidv4 = require('uuid/v4');

/**
 * Get division list by election 
 * @param {*} req 
 */
const getDivisionsByElectionId = async (req) => {
    try {
        const electionId = req.params.electionId;
        const divisions = await DivisionRepo.fetchDivisionsByElectionId(electionId);
        if (!_.isEmpty(divisions)) {
            return DivisionManager.mapToDivisionModel(divisions);
        } else {
            throw new ApiError("Divisions not found", DIVISION_NOT_FOUND_CODE);
        }
    } catch (error) {
        throw new ServerError("Server Error", HTTP_CODE_404);
    }
}

/**
 * Get eligible division list with nominations for particular election and team
 * @param {*} req 
 */
const getDivisionsWithNomination = async (req) => {
    try {
        const electionId = req.params.electionId;
        const teamId = req.params.teamId;
        const divisions = await DivisionRepo.fetchDivisionsWithNomination(electionId, teamId);
        if (!_.isEmpty(divisions)) {
            return DivisionManager.mapToDivisionModelWithNominations(divisions);
        } else {
            throw new ApiError("Divisions not found", DIVISION_NOT_FOUND_CODE);
        }
    } catch (error) {
        throw new ServerError("Server Error", HTTP_CODE_404);
    }
}

/**
 * Add division set with relates to module_id
 * @param {params, body} req 
 */
const addDivisonsByModuleId = async (req) => {
    try {
        const module_id = req.params.moduleId;
        const division_set = req.body;

        const divisions = division_set.map((division) => {
            return(
                {
                    'ID': uuidv4(),
                    'NAME': division.divisionName, 
                    'CODE': division.divisionCode, 
                    'NO_OF_CANDIDATES': parseInt(division.divisionCode),
                    'MODULE_ID': module_id,
                }
            );
        });
        return DivisionRepo.insertDivisionsByModuleId(divisions);
    } catch (error) {
        throw new ServerError("Server error", HTTP_CODE_404);
    }
}

export default {
    getDivisionsByElectionId,
    getDivisionsWithNomination,
    addDivisonsByModuleId,
}