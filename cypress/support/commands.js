// ***********************************************
// This example commands.js shows you how to
// create various custom commands and overwrite
// existing commands.
//
// For more comprehensive examples of custom
// commands please read more here:
// https://on.cypress.io/custom-commands
// ***********************************************
//
//
// -- This is a parent command --
// Cypress.Commands.add("login", (email, password) => { ... })
//
//
// -- This is a child command --
// Cypress.Commands.add("drag", { prevSubject: 'element'}, (subject, options) => { ... })
//
//
// -- This is a dual command --
// Cypress.Commands.add("dismiss", { prevSubject: 'optional'}, (subject, options) => { ... })
//
//
// -- This will overwrite an existing command --
// Cypress.Commands.overwrite("visit", (originalFn, url, options) => { ... })

const _ = Cypress._;
const $ = Cypress.$;

// repeatedly tries resolving the function until later assertions pass
Cypress.Commands.add('thenTry', { prevSubject: 'optional' },
    (subject, fn) => {
        const consoleProps = {
            'On': $(subject),
            'Fn': fn,
        };
        Cypress.log({
            $el: $(subject),
            name: 'thenTry',
            consoleProps: () => consoleProps,
        });

        return function resolve() {
            const result = fn(subject);
            consoleProps.Result = result;
            return cy.verifyUpcomingAssertions(result, { log: true }, {
                onRetry: resolve,
            });
        }();
    }
)

// resolves with whichever branch successfully passes assertions first
// (using thenTry)
Cypress.Commands.add('thenSelect', { prevSubject: 'optional' },
    (subject, ...fns) => {
        const branchCount = fns.length
        let branch = -1

        Cypress.log({
            $el: $(subject),
            name: 'thenSelect',
        })

        cy.wrap(subject).thenTry(elem => {
            branch = (branch + 1) % branchCount
            fns[branch](elem)
        })
    }
)

// fetches the for= value of a label (doesn't find inputs within the label)
Cypress.Commands.add('target', { prevSubject: true }, (label) => {
    if (label.get(0).tagName.toLowerCase() !== 'label') {
        console.error("invalid label:", label.get(0))
        throw Error('target must be called on label')
    }

    cy.wrap(label).thenSelect(
        label => {
            cy.get('input#' + label.attr('for'))
        },
        label => {
            label.find('input')
        },
    )
})
