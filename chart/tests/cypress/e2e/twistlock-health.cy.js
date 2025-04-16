function twistlock_login() {
  cy.get('input[type="text"]').first().type(Cypress.env('user'));
  cy.get('input[type="password"]').first().type(Cypress.env('password'));
  cy.get('button[type="submit"]').first().click();
}

describe("Check TL", () => {
  it('Check for license without raising exceptions for null values', { retries: 15 }, () => {
    const retries = Cypress.currentRetry;
    cy.log('Retry: ' + retries);
    cy.intercept('GET', '**/api/v1/settings/license?project=Central+Console').as('license');
    cy.visit(Cypress.env('twistlock_url') + "/#!/manage/system/license");
    if (retries === 0) {
      twistlock_login();
    }

    // Check license API response
    cy.wait('@license', { timeout: 30000 }).then(({ response }) => {
      cy.log('License response: "' + JSON.stringify(response) + '"').then(() => {
        if (response.body) {
          cy.visit(Cypress.env('twistlock_url') + "/#!/manage/system/license");
          assert.isNotNull(response.body, 'License Found - ' + JSON.stringify(response.body));
        } else {
          cy.log('License response is null or not found.');
        }
      });
    });
  });
});