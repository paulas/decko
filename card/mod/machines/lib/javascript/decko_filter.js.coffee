$(window).ready ->
  $('body').on "change", "._filter_input_field", ->
    form = $(this).closest("._filter_form")
    form.submit()

  $('body').on "click", "._filter_category_select", ->
    addFilterDropdown = $(this).closest("._add_filter_dropdown")
    category = $(this).data("category")
    label = $(this).data("label")
    filterCategorySelected(addFilterDropdown, category, label)

  $('body').on "click", "._delete_filter_input", ->
    form = $(this).closest("._filter_form")
    input = $(this).closest("._filter_input")
    addCategoryOption(form, input.data("category"))
    input.remove()
    form.submit()

filterCategorySelected = (addFilterDropdown, selectedCategory, label) ->
  removeCategoryOption(addFilterDropdown, selectedCategory)

  widget = addFilterDropdown.closest("._filter_widget")

  # add new search input field
  $searchInputField = $(widget.find("._filter_input_field_prototypes > ._filter_input_field.#{selectedCategory}")[0])

  # deal with select2
  # $searchInputField.find(".select2-hidden-accessible").select2("destroy")
  # $searchInputField = $($searchInputField.html()).clone(true)
  # $searchInputField.find("select").select2()

  $(widget.find("._add_filter_dropdown")).before($searchInputField)
  $searchInput.find("._filter_input_field").focus()


addCategoryOption = (form, option) ->
  form.find("._filter_category_select[data-category='#{option}']").show()

removeCategoryOption = (form, option) ->
  form.find("._filter_category_select[data-category='#{option}']").hide()
