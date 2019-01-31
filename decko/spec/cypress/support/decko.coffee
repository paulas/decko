Cypress.Commands.add "login", (email="joe@admin.com", password="joe_pass") =>
  cy.request
    method: "POST",
    url: "/update/*signin",
    body:
      card:
        subcards:
          "+*email": { content: email }
          "+*password": { content: password }

# find card slot by card name (and view)
Cypress.Commands.add "slot", (cardname, view) =>
  selector = ".card-slot.SELF-#{cardname}"
  selector += ".#{view}-view" if view?
  cy.get(selector)

# click the edit icon
Cypress.Commands.add "click_edit",  { prevSubject: 'element'}, (subject) =>
  subject.find(".card-menu > a").click(force: true)

Cypress.Commands.add "expect_main_title", (text) =>
  cy.get("#main > .card-slot > .d0-card-frame > .d0-card-header > .d0-card-header-title > .card-title")
    .should("contain", text)

Cypress.Commands.add "expect_main_content", (text) =>
  cy.get("#main > .card-slot > .d0-card-frame > .d0-card-body")
    .should("contain", text)

Cypress.Commands.add "rename", (old_name, new_name) =>
  cy.request
    method: "POST",
    url: "/update/#{old_name}?card[name]=#{new_name}"

Cypress.Commands.add "retype", (name, new_type) =>
  cy.request
    method: "POST",
    url: "/update/#{name}?card[type]=#{new_type}"

Cypress.Commands.add "clear_machine_cache", () =>
  cy.request
    method: "POST",
    url: "/update/*admin?task=clear_machine_cache"

Cypress.Commands.add "select2", prevSubject: "optional", (subject, name, value) =>
  selector = "select[name='card[type]'] + .select2-container"
  if subject
    subject.find(selector).click()
  else
    cy.get(selector).click()

  cy.get("span.select2-results").contains(value).click()
