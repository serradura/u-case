CallFlows = -> (params:) do
  -> (x) do
    x.config(time: 5, warmup: 2)
    x.time = 5
    x.warmup = 2

    [
      interactor                        = -> { AddFiveWith::Interactor::Organizer.call(params) },
      u_case_flow_collection            = -> { AddFiveWith::MicroCase::Flow::Collection.call(params) },
      u_case_flow_collection_in_a_class = -> { AddFiveWith::MicroCase::Flow::CollectionInAClass.call(params) },
      u_case_flow_including_the_class   = -> { AddFiveWith::MicroCase::Flow::IncludingTheClass.call(params) },
      u_case_flow_using_result_pipes    = -> { AddFiveWith::MicroCase::Flow::UsingResultPipes.call(params) },
      u_case_flow_using_result_thens    = -> { AddFiveWith::MicroCase::Flow::UsingResultThens.call(params) }
    ].each(&:call)

    x.report('Interactor::Organizer', &interactor)
    x.report('Micro::Cases.flow([])', &u_case_flow_collection)
    x.report('Micro::Case flow in a class', &u_case_flow_collection_in_a_class)
    x.report('Micro::Case including the class', &u_case_flow_including_the_class)
    x.report('Micro::Case::Result#|', &u_case_flow_using_result_pipes)
    x.report('Micro::Case::Result#then', &u_case_flow_using_result_thens)

    x.compare!
  end
end
