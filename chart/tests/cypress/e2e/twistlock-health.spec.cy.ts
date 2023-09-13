//let customWaitTime:number;
//describe('Twistlock Healthcheck', function() {
//  before(() => {
//    const envVarString: string | undefined = Cypress.env('waittime');
//    if (envVarString !== undefined) {
//      // Parse the string into an integer using parseInt
//      customWaitTime = parseInt(envVarString, 10); // 10 represents base 10
//      if (isNaN(customWaitTime)) {
//        customWaitTime = 10000;
//      } 
//    }else{
//      customWaitTime = 10000;
//    }
//    
//  })
//  
//  it('Check console is accessible', function() {
//    cy.visit(Cypress.env('url'), { timeout: customWaitTime })
//    cy.title().should('eq', 'Prisma Cloud')
//  })

  /* Below section should work, but times out because either one of Cypress or Twistlock doesn't play nice.
  it('Create admin user', function() {
    cy.get('input[type="text"]').type("admin")
    cy.get('input[type="password"]').type(Cypress.env('twistlock_password'))
    cy.get('button[type="submit"]').click()
  })*/
//})
