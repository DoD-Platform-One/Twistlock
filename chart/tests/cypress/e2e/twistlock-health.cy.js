//If values are specified use those, otherwise, use default values
const customWaitTime = Cypress.env('timeout') ?? 10000

describe('Twistlock Healthcheck', function () {
  it('Check console is accessible and can log in', function () {
    // Refer to https://repo1.dso.mil/big-bang/product/packages/twistlock/-/issues/76
    // cy.visit(Cypress.env('url'));
    // cy.title().should('eq', 'Prisma Cloud');
    // cy.get('input[type="text"]', {timeout: customWaitTime}).type("admin");
    // cy.get('input[type="password"]').type(Cypress.env('twistlock_password'));
    // cy.get('button[type="submit"]').click();
  });
});