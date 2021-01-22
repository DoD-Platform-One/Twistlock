describe('Basic Twistlock Up', function() {
  it('Check console is accessible', () => {
    cy.visit(Cypress.env('twistlock_url'));
    cy.title().should('eq', 'Prisma Cloud');
  });
})
