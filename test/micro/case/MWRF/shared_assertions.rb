# frozen_string_literal: true

class Micro::Case::MWRF
  module SharedAssertions
    UUID_FORMAT = /\b[0-9a-f]{8}\b-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-\b[0-9a-f]{12}\b/

    def use_case
      raise NotImplementedError
    end

    def test_the_use_case_result
      result = use_case.call({
        "name" => "  Rodrigo  \n  Serradura ",
        "email" => "   RoDRIGo.SERRAdura@gmail.com   "
      })

      assert result.success?

      user, crm_id = result.values_at(:user, :crm_id)

      assert_match(UUID_FORMAT, crm_id)

      assert_match(UUID_FORMAT, user.id)
      assert_equal('Rodrigo Serradura', user.name)
      assert_equal('rodrigo.serradura@gmail.com', user.email)

      # --

      [
        use_case.call(name: 'A', email: ''),
        use_case.call(name: '', email: 'a@a.com')
      ].each do |use_case_result|
        assert_predicate(use_case_result, :failure?)
      end
    end
  end
end
