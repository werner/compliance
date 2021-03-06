class Api::PeopleController < Api::ApiController
  def index
    scope = Person.ransack(params[:filter]).result

    page, per_page = Util::PageCalculator.call(params, 0, 10)
    people = scope.page(page).per(per_page)
    jsonapi_response people,
      meta: { total_pages: (scope.count.to_f / per_page).ceil }
  end

  def show
    jsonapi_response Person
      .preload(*Person::eager_person_entities)
      .find(params[:id])
  end

  def create
    jsonapi_response Person.create, {}, 201
  end
end
