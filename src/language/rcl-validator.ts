import type { ValidationChecks } from 'langium';
import type { RclAstType } from './generated/ast.js';
import type { RclServices } from './rcl-module.js';

/**
 * Register custom validation checks.
 */
export function registerValidationChecks(services: RclServices) {
    const registry = services.validation.ValidationRegistry;
    const validator = services.validation.RclValidator;
    const checks: ValidationChecks<RclAstType> = {
        // Add validation checks here as needed
    };
    registry.register(checks, validator);
}

/**
 * Implementation of custom validations.
 */
export class RclValidator {

    // Add validation methods here as needed

}
