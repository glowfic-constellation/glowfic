describe('Registration', () => {
    it('lets you create an account and log in', () => {
        cy.visit('/')

        cy.contains('a:visible', 'Sign up').click()

        const placeholdered = (placeholder) => (
            cy.get(`input[placeholder^='${placeholder}']`)
        )

        cy.get('#content').within(() => {
            placeholdered('Username').type('John Doe')
            placeholdered('Email').type('user@example.com')
            placeholdered('Password').type('password123')
            placeholdered('Confirm').type('password123')
            placeholdered('Secret').type('ALLHAILTHECOIN')
            cy.contains('label', 'Terms of Service').target().check()
            cy.contains('input', 'Sign Up').click()
        })

        cy.contains('.flash.success', 'User created! You have been logged in.')
        cy.contains('John Doe')
    })
})
