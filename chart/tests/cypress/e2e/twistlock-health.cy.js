function twistlock_login() {
  cy.get('input[type="text"]').type(Cypress.env('user'));
  cy.get('input[type="password"]').type(Cypress.env('password'));
  cy.get('button[type="submit"]').click();
}

describe("Check TL", () => {
  it('Check for license and that a defender pod is running on all Nodes', () => {
    cy.intercept('GET', '**/api/v1/settings/license?project=Central+Console').as('license');
    cy.intercept('GET', '**/api/v1/radar/container/clusters?project=Central+Console').as('nodes');
    cy.intercept('GET', '**/api/v1/stats/dashboard?project=Central+Console').as('defenders');
    let defendersCount, nodesCount; 
    cy.visit(Cypress.env('twistlock_url') + "/#!/manage/system/license");
    twistlock_login();

    cy.wait('@license', { timeout: 30000 }).then(({ response }) => {
      assert.isNotNull(response.body, 'License not Found');
    });

    cy.visit(Cypress.env('twistlock_url') + "/#!/radars/hosts");  
    cy.wait('@defenders', { timeout: 300000 }).then(({ response }) => {
      defendersCount = response.body.defendersSummary.container;    
    });
    
    cy.visit(Cypress.env('twistlock_url') + "/#!/radars/containers");
    cy.wait('@nodes', { timeout: 300000 }).then(({ response }) => {
        console.log(response);
        cy.log(response);
        nodesCount = response.body[0].hostCount;
      });
    
    expect(defendersCount).to.equal(nodesCount);
 });
});
