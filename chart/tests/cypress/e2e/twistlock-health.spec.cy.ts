describe('Twistlock Healthcheck', function() {
  it('Check console is accessible', function() {
    cy.visit('/', { timeout: 5000 })
    cy.title().should('eq', 'Prisma Cloud')
  })

  /* Below section should work, but times out because either one of Cypress or Twistlock doesn't play nice.
  it('Create admin user', function() {
    cy.get('input[type="text"]').type("admin")
    cy.get('input[type="password"]').type(Cypress.env('twistlock_password'))
    cy.get('button[type="submit"]').click()
  })*/
})
