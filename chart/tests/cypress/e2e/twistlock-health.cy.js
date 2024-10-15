function twistlock_login() {
  cy.get('input[type="text"]').first().type(Cypress.env('user'));
  cy.get('input[type="password"]').first().type(Cypress.env('password'));
  cy.get('button[type="submit"]').first().click();
}

function check_defenders_and_nodes(finished, total, defendersCount, nodesCount) {
  if (finished < total) {
    return;
  }
  expect(defendersCount).to.equal(nodesCount);
  expect(defendersCount).to.be.greaterThan(0);
}

describe("Check TL", () => {
  it('Check for license and that a defender pod is running on all Nodes', {retries:15}, () => {
    const retries = Cypress.currentRetry;
    const total = 3;
    let defendersCount, nodesCount;
    let finished = 0;

    cy.log('Retry: ' + retries);

    cy.intercept('GET', '**/api/v1/radar/container/clusters?project=Central+Console').as('nodes');
    cy.intercept('GET', '**/api/v1/stats/dashboard?project=Central+Console').as('defenders');
    cy.intercept('GET', '**/api/v1/settings/license?project=Central+Console').as('license');

    cy.visit(Cypress.env('twistlock_url') + "/#!/manage/system/license");
    if (retries === 0) {
      twistlock_login();
    }
    cy.wait('@license', { timeout: 30000 }).then(({ response }) => {
      cy.log('license response: "' + JSON.stringify(response) + '"').then(() => {
        assert.isNotNull(response.body, 'License not Found - ' + response.body);
        finished++;
        check_defenders_and_nodes(finished, total, defendersCount, nodesCount);
      });
    });

    cy.visit(Cypress.env('twistlock_url') + "/#!/radars/hosts");
    cy.wait('@defenders', { timeout: 30000 }).then(({ response }) => {
      cy.log('defenders response: "' + JSON.stringify(response) + '"').then(() => {
        defendersCount = response.body.defendersSummary.container;
        finished++;
        check_defenders_and_nodes(finished, total, defendersCount, nodesCount);
      });
    });

    cy.visit(Cypress.env('twistlock_url') + "/#!/radars/containers");
    cy.wait('@nodes', { timeout: 30000 }).then(({ response }) => {
      cy.log('containers response: "' + JSON.stringify(response) + '"').then(() => {
        nodesCount = response.body[0].hostCount;
        finished++;
        check_defenders_and_nodes(finished, total, defendersCount, nodesCount);
      });
    });
  });
});
