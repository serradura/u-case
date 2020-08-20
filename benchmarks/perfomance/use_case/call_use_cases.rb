CallUseCases = -> (params:) do
  -> (x) do
    x.config(time: 5, warmup: 2)
    x.time = 5
    x.warmup = 2

    [
      interactor      = -> { MultiplyWith::Interactor.call(params) },
      trailblazer     = -> { MultiplyWith::Trailblazer.call(params) },
      dry_monads      = -> { MultiplyWith::DryMonads.new.call(params) },
      dry_transaction = -> { MultiplyWith::DryTransaction.new.call(params) },
      u_case          = -> { MultiplyWith::MicroCase.call(params) },
      u_case_safe     = -> { MultiplyWith::MicroCaseSafe.call(params) },
      u_case_strict   = -> { MultiplyWith::MicroCaseStrict.call(params) }
    ].each(&:call)

    x.report('Interactor', &interactor)
    x.report('Trailblazer::Operation', &trailblazer)
    x.report('Dry::Monads', &dry_monads)
    x.report('Dry::Transaction', &dry_transaction)
    x.report('Micro::Case', &u_case)
    x.report('Micro::Case::Safe', &u_case_safe)
    x.report('Micro::Case::Strict', &u_case_strict)

    x.compare!
  end
end
