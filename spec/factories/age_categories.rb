# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :age_category do
    name "MyString"
    from_age 1
    to_age 1
  end
end
