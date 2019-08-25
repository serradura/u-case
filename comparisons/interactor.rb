class CreateResponse
  include Interactor

  def call
    responder = context.responder

    survey_response = responder.survey_responses.build(
      response_text: context.answers[:text],
      rating: answers[:rating],
      survey: context.survey
    )

    if survey_response.save
      context.survey_response = survey_response
    else
      context.fail!(errors: survey_response.errors)
    end
  end
end

class AddRewardPoints
  include Interactor

  def call
    reward_account = context.responder.reward_account

    reward_account.balance += context.survey.reward_points

    unless reward_account.save
      context.fail!(errors: reward_account.errors)
    end
  end
end

class SendNotifications
  include Interactor

  def call
    sender = context.survey.sender

    SurveyMailer.delay.notify_responder(context.responder.id)
    SurveyMailer.delay.notify_sender(sender.id)

    unless sender.add_survey_response_notification
      context.fail!(errors: sender.errors)
    end
  end
end

class ReplyToSurvey
  include Interactor::Organizer

  organize CreateResponse, AddRewardPoints, SendNotifications
end

# https://gist.githubusercontent.com/raderj89/cbb84b1f75e67087388bc4cdbe617138/raw/a39c3ba6b416ac3919cc7d32bfa58e82211f24ef/interactor_example.rb
# https://medium.com/reflektive-engineering/from-service-objects-to-interactors-db7d2bb7dfd9
