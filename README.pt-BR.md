<p align="center">
  <h1 align="center" id="-case"><img src="./assets/u-case-logo-v3.png" alt="μ-case" height="250"></h1>
  <p align="center"><i>Represente casos de uso de forma simples e poderosa: escreva código modular, expressivo e sequencialmente lógico.</i></p>
  <p align="center">
    <a href="https://badge.fury.io/rb/u-case"><img src="https://badge.fury.io/rb/u-case.svg" alt="Gem Version" height="18"></a>
    <a href="https://github.com/serradura/u-case/actions/workflows/ci.yml"><img alt="Build Status" src="https://github.com/serradura/u-case/actions/workflows/ci.yml/badge.svg"></a>
    <br/>
    <a href="https://qlty.sh/gh/serradura/projects/u-case"><img src="https://qlty.sh/gh/serradura/projects/u-case/maintainability.svg" alt="Maintainability" /></a>
    <a href="https://qlty.sh/gh/serradura/projects/u-case"><img src="https://qlty.sh/gh/serradura/projects/u-case/coverage.svg" alt="Code Coverage" /></a>
    <br/>
    <img src="https://img.shields.io/badge/Ruby%20%3E%3D%202.7%2C%20%3C%3D%20Head-ruby.svg?colorA=444&colorB=333" alt="Ruby">
    <img src="https://img.shields.io/badge/Rails%20%3E%3D%206.0%2C%20%3C%3D%20Edge-rails.svg?colorA=444&colorB=333" alt="Rails">
  </p>
  <p align="center">🇺🇸 <a href="https://github.com/serradura/u-case/blob/main/README.md">Read this README in English</a></p>
</p>

> [!IMPORTANT]
> **Sem breaking changes na API — nunca.** Daqui em diante, a API pública e os contratos de runtime do `u-case` não vão quebrar. O papel da gem é continuar sendo uma base estável e retrocompatível para os projetos que já dependem dela. Qualquer "próximo major" que repense as abstrações pertence ao [`solid-process`](https://github.com/solid-process/solid-process) (um redesign que aplica o que aprendemos desde a criação do `u-case`), e **não** a um futuro `u-case` 6.x.
>
> Bumps de versão major sinalizam apenas que uma versão do Ruby ou do Rails deixou de ser suportada.
>
> Veja a declaração completa na [issue #131](https://github.com/serradura/u-case/issues/131#issuecomment-4531231882).

## Quick start <!-- omit in toc -->

Esse é o formato inteiro: `attributes`, um método `call!`, e `Success(...)` ou `Failure(...)`. Todo o resto deste README é uma forma de tornar esse formato mais fácil de **compor**, **validar**, **observar** e **transacionar**.

```ruby
require 'u-case'

class Slugify < Micro::Case
  attribute :title, accept: String

  def call!
    slug = title.downcase.strip.gsub(/[^a-z0-9]+/, '-').gsub(/^-|-$/, '')

    slug.empty? ? Failure(:blank_title) : Success(result: { slug: })
  end
end

Slugify.call(title: 'Hello, World!')
# => #<Micro::Case::Result success? type=:ok data={ slug: "hello-world" }>

Slugify
  .call(title: 42)
  .on_success { puts it[:slug] }
  .on_failure(:invalid_attributes) { warn it[:errors] }
# warn: { "title" => "expected to be a kind of String" }

# ---------------------------------------------
# Ramificando em cima do resultado? Use pattern matching:
# ---------------------------------------------
case Slugify.call(title: 'Hello, World!')
in { success: _,                   result: { slug: } }
  redirect_to "/posts/#{slug}"
in { failure: :invalid_attributes, result: { errors: } }
  render status: 422, json: { errors: }
in { failure: :blank_title }
  render status: 422, json: { error: 'title required' }
end
```

Precisa de uma entrada estruturada? Declare atributos com um bloco — os atributos filhos herdam o mix de features do host (veja [Indo além com `u-attributes`](#indo-além-com-u-attributes)):

```ruby
class CreateOrder < Micro::Case
  attribute :id, accept: Integer

  attribute :customer do
    attribute :name,  accept: String
    attribute :email, accept: String
  end

  def call!
    transaction do
      customer = Customer.find_or_create_by!(name: customer.name, email: customer.email)

      order = Order.create!(id:, customer_id: customer.id)

      Success result: { customer:, order: }
    end
  end
end
```

Precisa de trabalho atômico em múltiplos steps? Envolva um flow inteiro em uma transação com um único kwarg, ou escope uma `ActiveRecord::Base.transaction` num único `call!`:

```ruby
# Um flow transacional — todos os steps dentro da mesma transação:
SignUp = Micro::Cases.flow(transaction: true, steps: [
  NormalizeParams,
  CreateUser,
  CreateProfile
])

# Uma transação inline { ... } dentro do call!:
class CreateUserWithProfile < Micro::Case
  def call!
    transaction {
      call(CreateUser).then(CreateProfile)
    }
  end
end
```

Veja [Compondo casos de uso](#compondo-casos-de-uso) e [Indo além com `u-attributes`](#indo-além-com-u-attributes) para a história completa.

## Recursos <!-- omit in toc -->

- **Fácil** — entrada → processamento → saída. Um caso de uso é uma classe pequena com `attributes` e um método `call!` que retorna um resultado.
- **Imutável e sem callbacks** — nada de callbacks de ciclo de vida `before` / `after` / `around`. Os dados fluem adiante; nada é mutado in place.
- **Componível de três formas** — encadeie casos de uso via [`Micro::Cases.flow`](#flows), via [macro `flow` no nível da classe](#flows), ou via cadeias inline de [`Result#then`](#steps-internos--cadeias-com-resultthen).
- **Resultados tipados** — toda chamada retorna um [`Micro::Case::Result`](#trabalhando-com-resultados) com um discriminante `success?`/`failure?`, um símbolo `:type` e um hash `data`.
- **Pattern matching** — o `case`/`in` do Ruby funciona em resultados direto ([Pattern matching](#pattern-matching)).
- **Contratos de resultado** — declare quais tipos de resultado e quais chaves seu caso de uso pode retornar; [usos incorretos falham loudly](#contratos-de-resultado).
- **Execução inspecionável** — todo flow registra a entrada, a saída e os atributos acessíveis de cada step em [`result.transitions`](#inspecionando-a-execução-com-resulttransitions). Debug, log ou audite como qualquer resultado foi produzido.
- ⚡ **Transações sob demanda** — envolva um caso de uso, um flow em uma [transação `ActiveRecord`](#transações).
- **Tratamento de exceções opt-in** — [`Micro::Case::Safe`](#modo-seguro--capturando-exceções) converte exceções não tratadas em falhas do tipo `:exception`.
- **Rápido** — Confira os [benchmarks](#performance), sem estado global.

> Veja uma aplicação Rails real que usa essa gem: [from-fat-controllers-to-use-cases](https://github.com/serradura/from-fat-controllers-to-use-cases).

## Documentação <!-- omit in toc -->

| Versão     | Documentação                                                  |
| ---------- | ------------------------------------------------------------- |
| unreleased | https://github.com/serradura/u-case/blob/main/README.pt-BR.md |
| 5.7.1      | https://github.com/serradura/u-case/blob/v5.x/README.pt-BR.md |
| 4.5.2      | https://github.com/serradura/u-case/blob/v4.x/README.pt-BR.md |

## Uma nota sobre sintaxe <!-- omit in toc -->

Os exemplos neste README usam dois recursos modernos do Ruby. A gem em si suporta Ruby `>= 2.7`, então se você está em um runtime mais antigo, aqui está como interpretá-los na forma clássica.

**[Parâmetro de bloco `it`](https://docs.ruby-lang.org/en/3.4/syntax/methods_rdoc.html#label-Numbered+parameters)** — Ruby 3.4+

```ruby
# Moderno (Ruby >= 3.4) — o que você verá ao longo deste README
attribute :title, accept: -> { it.is_a?(String) && !it.empty? }
Slugify.call(title: 'Olá').on_success { puts it[:slug] }

# Clássico — equivalente em todo Ruby suportado
attribute :title, accept: ->(value) { value.is_a?(String) && !value.empty? }
Slugify.call(title: 'Olá').on_success { |data| puts data[:slug] }
```

**[Omissão de valor em hash](https://docs.ruby-lang.org/en/3.1/syntax/literals_rdoc.html#label-Hash+Literals)** — Ruby 3.1+

Quando a chave de um hash coincide com o nome de uma variável local (ou método) no escopo, você pode omitir o valor:

```ruby
slug = 'ola-mundo'

# Moderno (Ruby >= 3.1)
Success(result: { slug: })

# Clássico — equivalente em todo Ruby suportado
Success(result: { slug: slug })
```

## Índice <!-- omit in toc -->

- [Compatibilidade](#compatibilidade)
- [Dependências](#dependências)
- [Instalação](#instalação)
- [Uso](#uso)
  - [Definindo um caso de uso](#definindo-um-caso-de-uso)
    - [O básico](#o-básico)
    - [Modo estrito — atributos obrigatórios](#modo-estrito--atributos-obrigatórios)
    - [Modo seguro — capturando exceções](#modo-seguro--capturando-exceções)
      - [Flows seguros](#flows-seguros)
      - [`Result#on_exception`](#resulton_exception)
      - [Desabilitando o Safe](#desabilitando-o-safe)
  - [Trabalhando com resultados](#trabalhando-com-resultados)
    - [A API do Result](#a-api-do-result)
    - [Tipos de resultado padrão e customizados](#tipos-de-resultado-padrão-e-customizados)
    - [Contratos de resultado](#contratos-de-resultado)
    - [Hooks de resultado](#hooks-de-resultado)
    - [Pattern matching](#pattern-matching)
    - [Decomposição](#decomposição)
    - [Continuações dinâmicas com `Result#then`](#continuações-dinâmicas-com-resultthen)
  - [Validando atributos](#validando-atributos)
    - [`accept:` e `reject:` (padrão)](#accept-e-reject-padrão)
    - [Integração com ActiveModel (opt-in)](#integração-com-activemodel-opt-in)
      - [Desabilitando a auto-validação em um caso específico](#desabilitando-a-auto-validação-em-um-caso-específico)
      - [`Kind::Validator`](#kindvalidator)
  - [Compondo casos de uso](#compondo-casos-de-uso)
    - [Flows](#flows)
      - [Compondo flows entre si](#compondo-flows-entre-si)
      - [Acumulação de dados através de um flow](#acumulação-de-dados-através-de-um-flow)
      - [Inspecionando a execução com `result.transitions`](#inspecionando-a-execução-com-resulttransitions)
      - [Compondo um flow que inclui a si mesmo](#compondo-um-flow-que-inclui-a-si-mesmo)
    - [Steps internos — cadeias com `Result#then`](#steps-internos--cadeias-com-resultthen)
      - [Formas aceitas de elo](#formas-aceitas-de-elo)
      - [Um exemplo mínimo](#um-exemplo-mínimo)
      - [Alias `|` (pipe)](#alias--pipe)
      - [Formas Lambda / `Method`](#formas-lambda--method)
      - [`Failure` interrompe a cadeia](#failure-interrompe-a-cadeia)
      - [Usando um caso com steps internos dentro de um flow externo](#usando-um-caso-com-steps-internos-dentro-de-um-flow-externo)
      - [Persistência sem transação](#persistência-sem-transação)
    - [Transações](#transações)
      - [`transaction { ... }` inline dentro do `call!`](#transaction----inline-dentro-do-call)
      - [`transaction with: …` — declarando o padrão para um caso](#transaction-with---declarando-o-padrão-para-um-caso)
      - [Transações no nível do flow](#transações-no-nível-do-flow)
      - [Padrão global — `config.default_transaction_class { … }`](#padrão-global--configdefault_transaction_class---)
      - [Flows com steps internos sob transações](#flows-com-steps-internos-sob-transações)
      - [Observações de comportamento](#observações-de-comportamento)
- [Configuração](#configuração)
- [Performance](#performance)
  - [Executando os benchmarks](#executando-os-benchmarks)
  - [Desabilitando os checks em runtime](#desabilitando-os-checks-em-runtime)
  - [Comparações](#comparações)
- [Exemplos](#exemplos)
  - [Um flow completo de cadastro](#um-flow-completo-de-cadastro)
  - [Mais exemplos](#mais-exemplos)
- [Indo além com `u-attributes`](#indo-além-com-u-attributes)
  - [Atributos aninhados (forma com bloco)](#atributos-aninhados-forma-com-bloco)
  - [Aceitando outra classe de atributos](#aceitando-outra-classe-de-atributos)
- [Desenvolvimento](#desenvolvimento)
- [Contribuindo](#contribuindo)
- [Licença](#licença)
- [Código de conduta](#código-de-conduta)

## Compatibilidade

| u-case     | branch | ruby     | activemodel    | u-attributes  |
| ---------- | ------ | -------- | -------------- | ------------- |
| unreleased | main   | >= 2.7   | >= 6.0         | >= 2.8, < 4.0 |
| 5.7.1      | v5.x   | >= 2.7   | >= 6.0         | >= 2.8, < 4.0 |
| 4.5.2      | v4.x   | >= 2.2.0 | >= 3.2, <= 8.1 | >= 2.7, < 3.0 |

Esta biblioteca é testada (matriz de CI) contra:

| Ruby / Rails | 6.0 | 6.1 | 7.0 | 7.1 | 7.2 | 8.0 | 8.1 | Edge |
| ------------ | --- | --- | --- | --- | --- | --- | --- | ---- |
| 2.7          | ✅  | ✅  | ✅  | ✅  |     |     |     |      |
| 3.0          | ✅  | ✅  | ✅  | ✅  |     |     |     |      |
| 3.1          |     |     | ✅  | ✅  | ✅  |     |     |      |
| 3.2          |     |     | ✅  | ✅  | ✅  | ✅  |     |      |
| 3.3          |     |     | ✅  | ✅  | ✅  | ✅  | ✅  | ✅   |
| 3.4          |     |     |     |     | ✅  | ✅  | ✅  | ✅   |
| 4.x          |     |     |     |     |     |     | ✅  | ✅   |
| Head         |     |     |     |     |     |     | ✅  | ✅   |

> ActiveModel é uma dependência opcional — habilite [`u-case/with_activemodel_validation`](#integração-com-activemodel-opt-in) apenas se quiser.

## Dependências

1. **[`kind`](https://github.com/serradura/kind)** — um sistema de tipos em runtime para Ruby, usado para validar alguns inputs internos do `u-case`. Também expõe o [`Kind::Validator`](https://github.com/serradura/kind#kindvalidator-activemodelvalidations) que vem junto do [`u-case/with_activemodel_validation`](#integração-com-activemodel-opt-in). Os exemplos abaixo usam `Kind.of?(SomeClass, *values)` como um atalho para checagem de tipos em runtime — equivalente a `values.all? { |v| v.is_a?(SomeClass) }`.
2. **[`u-attributes`](https://github.com/serradura/u-attributes)** — declarações de atributos read-only (somente getters). Usada para os `attributes` do caso de uso.

## Instalação

Adicione essa linha ao Gemfile da sua aplicação:

```ruby
gem 'u-case', '~> 5.0'
```

Então execute `bundle`, ou instale manualmente com `gem install u-case`.

## Uso

### Definindo um caso de uso

#### O básico

```ruby
class ValidateEmail < Micro::Case
  # 1. Declare a entrada como atributos
  attribute :address

  # 2. Implemente call! com a regra de negócio
  def call!
    # 3. Envolva o resultado com Success(...) ou Failure(...)
    if address.is_a?(String) && address.match?(/\A[^@\s]+@[^@\s]+\.[^@\s]+\z/)
      Success result: { address: address.downcase }
    else
      Failure result: { message: '`address` must be a valid email' }
    end
  end
end

result = ValidateEmail.call(address: 'Ada@Example.com')
result.success? # => true
result.data     # => { address: "ada@example.com" }

bad_result = ValidateEmail.call(address: 'not-an-email')
bad_result.failure? # => true
bad_result.data     # => { message: "`address` must be a valid email" }
```

O objeto retornado por `.call` é um [`Micro::Case::Result`](#trabalhando-com-resultados) — assunto da próxima seção.

#### Modo estrito — atributos obrigatórios

`Micro::Case::Strict` exige que todos os atributos declarados sejam passados em `.call`. Keywords faltantes lançam `ArgumentError`:

```ruby
class FormatGreeting < Micro::Case::Strict
  attributes :name, :time_of_day

  def call!
    Success result: { message: "Good #{time_of_day}, #{name}!" }
  end
end

FormatGreeting.call(name: 'Ada')
# => ArgumentError (missing keyword: :time_of_day)
```

Use quando você quer que input ausente falhe loudly em vez de deixar `time_of_day` chegar como `nil` e produzir uma mensagem silenciosamente errada.

#### Modo seguro — capturando exceções

`Micro::Case::Safe` é outra classe base. Ela intercepta automaticamente qualquer exceção lançada dentro do `call!` e a converte em um `Failure` com `type: :exception`. A exceção em si fica disponível em `result[:exception]`:

```ruby
require 'json'
require 'logger'

AppLogger = Logger.new(STDOUT)

class ParseJsonPayload < Micro::Case::Safe
  attribute :payload

  def call!
    return Failure(:blank_payload) if payload.to_s.empty?

    Success result: { data: JSON.parse(payload) }
  end
end

result = ParseJsonPayload.call(payload: 'not-valid-json')
result.type                                 # => :exception
result.data                                 # => { exception: #<JSON::ParserError ...> }
result[:exception].is_a?(JSON::ParserError) # => true

result.on_failure(:exception) do
  AppLogger.error(it[:exception].message)
end
```

Para decidir o que fazer em função da classe da exceção, use `case`/`when` (ou [pattern matching](#pattern-matching)) dentro do hook:

```ruby
result.on_failure(:exception) do |data, use_case|
  case (e = data[:exception])
  when JSON::ParserError then AppLogger.error("malformed JSON: #{e.message}")
  else                        AppLogger.debug("#{use_case.class.name} raised #{e.class}")
  end
end
```

Você ainda pode capturar exceções explicitamente com `rescue` dentro de um caso de uso Safe — veja [estes exemplos de teste](https://github.com/serradura/u-case/blob/main/test/micro/case/safe_test.rb).

##### Flows seguros

Um flow seguro intercepta exceções em qualquer um de seus steps:

```ruby
module Users
  Create = Micro::Cases.safe_flow([
    ProcessParams,
    ValidateParams,
    Persist,
    SendToCRM
  ])

  # Ou como uma classe:
  class Create < Micro::Case::Safe
    flow ProcessParams,
         ValidateParams,
         Persist,
         SendToCRM
  end
end
```

##### `Result#on_exception`

Exceções ficam mais fáceis de acompanhar quando são tratadas como qualquer outra falha. `Result#on_exception` é um hook que dispara quando o `type` é `:exception` — funciona igual a `on_failure(:exception)`, mas torna a intenção explícita:

```ruby
class ParseJsonPayload < Micro::Case::Safe
  attribute :payload

  def call!
    Success result: { data: JSON.parse(payload) }
  end
end

ParseJsonPayload
  .call(payload: 'not-valid-json')
  .on_success { puts it[:data].inspect }
  .on_exception(Encoding::CompatibilityError) { puts 'Encoding mismatch.' }
  .on_exception(JSON::ParserError) { puts 'Malformed JSON.' }
  .on_exception { |_e, _use_case|  puts 'Something went wrong.' }
# Malformed JSON.
# Something went wrong.
```

> Tanto o `on_exception(JSON::ParserError)` tipado quanto o `on_exception` genérico disparam — como todos os hooks do u-case, todo match executa na ordem em que foi declarado (veja [Hooks de resultado](#hooks-de-resultado)).

##### Desabilitando o Safe

O mecanismo Safe é opinativo: qualquer exceção não tratada vira uma falha `:exception`. Essa conveniência pode fragmentar uma codebase — algumas exceções tratadas com `rescue` dentro de `call!`, outras com `on_exception` depois. Se você prefere uma única convenção explícita (apenas `rescue` puro), desabilite o Safe inteiro:

```ruby
Micro::Case.config do |config|
  config.disable_safe_features = true
end
```

Quando setado para `true`, os itens abaixo lançam `Micro::Case::Error::SafeFeaturesDisabled`:

- herdar de `Micro::Case::Safe`
- chamar `Micro::Cases.safe_flow(...)`
- chamar `Micro::Case::Result#on_exception`

[⬆️ Voltar ao topo](#índice-)

### Trabalhando com resultados

Um `Micro::Case::Result` carrega a saída do caso de uso. Os métodos que você mais vai usar:

#### A API do Result

- `#success?` / `#failure?` — discriminantes booleanos.
- `#type` — `Symbol` que descreve o resultado (`:ok`, `:error`, `:exception`, ou qualquer tipo customizado).
- `#data` — o hash de dados do resultado. `#value` é um alias retrocompatível.
- `#[]`, `#values_at`, `#fetch`, `#fetch_values`, `#keys`, `#key?`, `#value?`, `#slice` — acesso similar a `Hash` em cima de `#data`.
- `#use_case` — a instância do caso de uso que produziu o resultado (útil para diagnóstico de falhas dentro de um flow).
- `#on_success` / `#on_failure` / `#on_exception` — hooks para ramificar em função do resultado.
- `#then` — aplica outro caso de uso (ou lambda / method / símbolo) a um resultado de sucesso; é a base dos [steps internos](#steps-internos--cadeias-com-resultthen) e das [continuações dinâmicas](#continuações-dinâmicas-com-resultthen).
- `#transitions` — array com cada step que produziu esse resultado; veja [inspecionando a execução](#inspecionando-a-execução-com-resulttransitions).

Objetos `Result` também suportam [pattern matching](#pattern-matching) e [decomposição em array](#decomposição).

#### Tipos de resultado padrão e customizados

Todo resultado carrega um tipo. Os padrões:

- `:ok` — para `Success(...)`.
- `:error` — para `Failure(...)` cujo payload é um `Hash`.
- `:exception` — para `Failure(result: some_exception)` (uma instância de `Exception`).

```ruby
class FetchUser < Micro::Case
  attribute :id

  def call!
    return Failure(result: { errors: { id: 'must be an Integer' } }) unless id.is_a?(Integer)

    Success result: { user: User.find(id) }
  rescue => exception
    Failure result: exception
  end
end

FetchUser.call(id: 1).type        # => :ok
FetchUser.call(id: 'x').type      # => :error
FetchUser.call(id: 999_999).type  # => :exception   (ActiveRecord::RecordNotFound)
```

Passe um símbolo como primeiro argumento de `Success(...)` / `Failure(...)` para dar ao resultado um tipo customizado:

```ruby
class MergeTags < Micro::Case
  attributes :primary, :secondary

  def call!
    if primary.is_a?(Array) && secondary.is_a?(Array)
      Success result: { tags: (primary + secondary).uniq }
    else
      Failure :invalid_input, result: {
        attributes: attributes.reject { |_, v| v.is_a?(Array) }
      }
    end
  end
end

MergeTags.call(primary: %w[ruby], secondary: 'rails').type # => :invalid_input
```

Passar apenas o símbolo (sem `result:`) é válido — o data vira `{ <símbolo> => true }`. Esse formato é útil como discriminante rápido dentro de um flow:

```ruby
def call!
  return Failure(:invalid_input) unless primary.is_a?(Array) && secondary.is_a?(Array)

  Success result: { tags: (primary + secondary).uniq }
end

# result.data => { invalid_input: true }
```

#### Contratos de resultado

Use a macro `results do |on| ... end` para declarar quais tipos de resultado seu caso de uso pode produzir e quais chaves cada um deles exige. Chamadas que usam um tipo não declarado lançam `Micro::Case::Error::UnexpectedResultType`; chamadas que omitem uma chave obrigatória declarada lançam `Micro::Case::Error::MissingResultKeys`.

```ruby
class PublishPost < Micro::Case
  attribute :post

  results do |on|
    on.failure(:already_published)
    on.failure(:missing_content)

    on.success(result: [:post])
  end

  def call!
    return Failure(:already_published) if post.published?
    return Failure(:missing_content)   if post.body.to_s.strip.empty?

    post.update!(status: :published, published_at: Time.current)
    Success result: { post: }
  end
end

PublishPost.call(post: ready_post).data        # => { post: #<Post ...> }
PublishPost.call(post: empty_post).type        # => :missing_content
PublishPost.call(post: already_live_post).type # => :already_published
```

Um tipo passado sem `result:` é declarado sem chaves obrigatórias (qualquer payload — incluindo o `{ type => true }` implícito de `Failure(:my_type)` — é aceito). Com `result: [:key1, :key2]`, essas chaves precisam estar presentes no hash de resultado; chaves extras são permitidas.

```ruby
class CreateComment < Micro::Case
  results do |on|
    on.success(result: [:comment])
    on.failure(:spam)
  end

  def call!
    Success(:moderated, result: { comment: ... }) # lança Micro::Case::Error::UnexpectedResultType
    # Success(result: { body: '...' })            # lança Micro::Case::Error::MissingResultKeys
    # Failure(:rate_limited)                      # lança Micro::Case::Error::UnexpectedResultType
  end
end
```

Observações:

- Casos de uso sem um bloco `results` mantêm o comportamento irrestrito anterior — o contrato é opt-in.
- Subclasses herdam o contrato do pai.
- A auto-falha produzida pela validação de atributos via [`accept:` / `reject:`](#accept-e-reject-padrão) escapa do contrato — combinar `results` com validação de atributos **não** exige declarar `:invalid_attributes`.
- Exceções capturadas pelo [`Micro::Case::Safe`](#modo-seguro--capturando-exceções) (que produzem `Failure(result: exception)`) também escapam do contrato.
- Contratos são independentes de [hooks](#hooks-de-resultado) e [pattern matching](#pattern-matching): o contrato dispara no momento da chamada `Success(...)` / `Failure(...)`, dentro do `call!`. Uma vez que o `Result` existe, quem chama consome ele normalmente — não há enforcement no lado de quem chama.

#### Hooks de resultado

`on_success` e `on_failure` ramificam em função do tipo do resultado. Passe um símbolo para casar com um tipo específico, ou nenhum argumento para casar com qualquer um:

```ruby
class ChangePassword < Micro::Case
  attributes :user, :new_password

  def call!
    return Failure(:weak,   result: { msg: 'password too short' }) unless new_password.is_a?(String) && new_password.length >= 8
    return Failure(:reused, result: { msg: 'password recently used' }) if user.recently_used?(new_password)

    user.update_password!(new_password)
    Success result: { user: }
  end
end

ChangePassword
  .call(user: ada, new_password: 'long-enough-1')
  .on_success { audit "password updated for #{it[:user].id}" }
  .on_failure(:weak)   { raise ArgumentError, it[:msg] }
  .on_failure(:reused) { raise ArgumentError, it[:msg] }

ChangePassword
  .call(user: ada, new_password: 'short')
  .on_failure { |_r, use_case| audit "#{use_case.class.name} failed" }   # 1. ChangePassword failed
  .on_failure(:weak)   { raise ArgumentError, it[:msg] }                 # 2. ArgumentError
```

> O caso de uso responsável pelo resultado está sempre disponível como o segundo argumento do bloco do hook.

Sem um tipo explícito, o bloco recebe o resultado inteiro, então você pode ramificar com um `case`:

```ruby
ChangePassword
  .call(user: ada, new_password: 'short')
  .on_failure do |result, use_case|
    case result.type
    when :weak   then raise ArgumentError, 'password too short'
    when :reused then raise ArgumentError, 'password recently used'
    else raise NotImplementedError
    end
  end
```

Se o mesmo hook for declarado múltiplas vezes, todo match dispara:

```ruby
calls = 0
result = ChangePassword.call(user: ada, new_password: 'long-enough-1')

result
  .on_success      { calls += 1 }
  .on_success      { calls += 1 }
  .on_success(:ok) { calls += 1 }
  .on_success(:ok) { calls += 1 }

calls # => 4
```

#### Pattern matching

`Micro::Case::Result` implementa [`deconstruct`](https://docs.ruby-lang.org/en/3.4/syntax/pattern_matching_rdoc.html) e [`deconstruct_keys`](https://docs.ruby-lang.org/en/3.4/syntax/pattern_matching_rdoc.html), então o `case`/`in` do Ruby funciona direto (requer Ruby ≥ 2.7):

```ruby
case result
in { success: _, data: { number: Numeric => number } }
  puts "got #{number}"
in { failure: :invalid_attributes, data: { invalid_attributes: errors } }
  warn "bad input: #{errors.keys.join(", ")}"
in { failure: :exception, data: { exception: } }
  warn "boom: #{exception.message}"
end
```

Os hash patterns expõem essas chaves:

| Chave          | Presente em   | Valor                                                                               |
| -------------- | ------------- | ----------------------------------------------------------------------------------- |
| `success:`     | só em sucesso | o `type` do resultado (ex. `:ok`)                                                   |
| `failure:`     | só em falha   | o `type` do resultado (ex. `:invalid_attributes`)                                   |
| `type:`        | sempre        | o `type` do resultado                                                               |
| `data:`        | sempre        | o hash de `data` do resultado                                                       |
| `result:`      | sempre        | alias de `data:` (espelha a keyword `Success(result: …)` usada no local da criação) |
| `use_case:`    | sempre        | a instância do caso de uso que produziu o resultado                                 |
| `transitions:` | sempre        | o array de `transitions` do resultado                                               |

`Result#deconstruct` retorna um array de três elementos `[status, type, data]` onde `status` é `:success` ou `:failure`, então array patterns podem usar o status como discriminante — espelhando como bibliotecas com classes `Success` / `Failure` separadas são pattern-matched, mesmo que `Micro::Case::Result` seja uma única classe:

```ruby
case result
in [:success, :ok, { number: Integer => n }]
  n
in [:failure, :invalid_attributes, { invalid_attributes: errors }]
  # ...
in [:failure, :exception, { exception: }]
  # ...
end
```

> `Result#to_ary` continua igual e retorna `[data, type]` (usado em multi-assignment, ex. `data, type = result`). O pattern matching do Ruby usa `#deconstruct`, então os dois métodos intencionalmente retornam formatos diferentes.

#### Decomposição

Dentro de um hook sem tipo, o resultado também pode ser decomposto em array `[data, type]`:

```ruby
ChangePassword
  .call(user: ada, new_password: 'short')
  .on_failure do |(data, type), use_case|
    case type
    when :weak   then raise ArgumentError, data[:msg]
    when :reused then raise ArgumentError, data[:msg]
    else raise NotImplementedError
    end
  end
```

#### Continuações dinâmicas com `Result#then`

`Result#then` aplica outro caso de uso (ou callable) a um resultado de sucesso — `Failure` curto-circuita. Use para construir continuações dinâmicas a partir de um resultado que já existe:

```ruby
class FindActiveUser < Micro::Case
  attribute :email

  def call!
    user = User.active.find_by(email:)

    return Success result: { user: } if user

    Failure result: { email: }
  end
end

class GenerateInviteToken < Micro::Case
  attribute :user

  def call!
    Success result: { user:, token: SecureRandom.hex(16) }
  end
end

FindActiveUser.call(email: 'unknown@example.com').then(GenerateInviteToken).failure? # => true
FindActiveUser.call(email: 'ada@example.com').then(GenerateInviteToken).data
# => { user: #<User ...>, token: "9f2b…" }
```

Passar um bloco yielda `self` (um `Micro::Case::Result`) e retorna o valor do bloco — útil para desembrulhar em um tipo não-Result:

```ruby
class FindUser < Micro::Case
  attribute :email

  def call!
    user = User.find_by(email:)

    user ? Success(result: { user: }) : Failure(:not_found)
  end
end

FindUser.call(email: 'ada@example.com').then  { it.success? ? it[:user].id : nil } # => 42
FindUser.call(email: 'unknown@example.com').then { it.success? ? it[:user].id : nil } # => nil
```

Passe um `Hash` extra para injetar atributos no próximo caso de uso:

```ruby
Todo::FindAllForUser
  .call(user: current_user, params: params)
  .then(Paginate)
  .then(Serialize::PaginatedRelationAsJson, serializer: Todo::Serializer)
  .on_success { render_json(200, data: it[:todos]) }
```

> `Result#then` também aceita um `Symbol`, um objeto `Method`, ou uma `Lambda` — veja [Steps internos](#steps-internos--cadeias-com-resultthen).

[⬆️ Voltar ao topo](#índice-)

### Validando atributos

#### `accept:` e `reject:` (padrão)

Desde a 5.2.0, todo caso de uso inclui a [extensão `accept` do `u-attributes`](https://github.com/serradura/u-attributes). Declare uma expectativa de tipo (ou qualquer predicado) no atributo, e o caso de uso falha automaticamente com `type: :invalid_attributes` quando um atributo é rejeitado — sem precisar validar dentro do `call!`:

```ruby
class CreateUser < Micro::Case
  attribute :name,  accept: String
  attribute :email, accept: ->(v) { v.is_a?(String) && v.include?('@') }
  attribute :age,   accept: Integer, allow_nil: true

  def call!
    Success result: { user: User.create!(attributes) }
  end
end

CreateUser.call(name: 'Bob', email: 'bob@example.com')
# => #<Success type=:ok ...>

CreateUser.call(name: 42, email: 'not-an-email')
# => #<Failure type=:invalid_attributes data={
#       errors: {
#         "name"  => "expected to be a kind of String",
#         "email" => "is invalid"
#       }
#     }>
```

O tipo da falha segue a mesma configuração usada pela integração com ActiveModel — veja `set_activemodel_validation_errors_failure` em [Configuração](#configuração).

#### Integração com ActiveModel (opt-in)

Você pode sobrepor regras estilo Rails (`validates`) em cima de `accept:` / `reject:` para validações mais ricas (`presence`, `numericality`, `format`, validators customizados…). Requer [`activemodel >= 6.0`](https://rubygems.org/gems/activemodel) na sua aplicação.

A forma mais simples — `validates` está disponível em todo caso de uso, e você falha manualmente:

```ruby
class CreatePost < Micro::Case
  attributes :title, :body

  validates :title, :body, presence: true
  validates :title, length: { maximum: 120 }

  def call!
    return Failure :invalid_attributes, result: { errors: self.errors } if invalid?

    Success result: { post: Post.create!(title:, body:) }
  end
end
```

Para fazer casos de uso **falharem automaticamente** quando `invalid?` é `true`, require o entry point de auto-validação:

```ruby
# Gemfile
gem 'u-case', require: 'u-case/with_activemodel_validation'
```

…ou habilite via [Configuração](#configuração). O exemplo então colapsa:

```ruby
require 'u-case/with_activemodel_validation'

class CreatePost < Micro::Case
  attributes :title, :body

  validates :title, :body, presence: true
  validates :title, length: { maximum: 120 }

  def call!
    Success result: { post: Post.create!(title:, body:) }
  end
end
```

Quando tanto `accept:` quanto validações do ActiveModel estão presentes, a ordem de execução é:

1. `u-attributes` resolve o default de cada atributo.
2. `u-attributes` roda as checagens de `accept:` / `reject:`.
3. `u-case` roda as validações do ActiveModel **apenas se** todos os atributos foram aceitos.

> A auto-validação também é herdada por `Micro::Case::Strict` e `Micro::Case::Safe`.

##### Desabilitando a auto-validação em um caso específico

Use a macro `disable_auto_validation`:

```ruby
require 'u-case/with_activemodel_validation'

class CountPosts < Micro::Case
  disable_auto_validation

  attribute :user
  validates :user, presence: true

  def call!
    Success result: { count: user.posts.count }
  end
end

CountPosts.call(user: nil)
# => NoMethodError (undefined method `posts' for nil:NilClass)
```

##### `Kind::Validator`

A [gem `kind`](https://github.com/serradura/kind) traz um [`Kind::Validator`](https://github.com/serradura/kind#kindvalidator-activemodelvalidations) para o ActiveModel que valida tipos usando seu sistema de tipos em runtime. Requerer `'u-case/with_activemodel_validation'` também carrega o `Kind::Validator`:

```ruby
class Todo::List::AddItem < Micro::Case
  attributes :user, :params

  validates :user,   kind: User
  validates :params, kind: ActionController::Parameters

  def call!
    todo_params = params.require(:todo).permit(:title, :due_at)
    todo = user.todos.create(todo_params)

    Success result: { todo: todo }
  rescue ActionController::ParameterMissing => e
    Failure :parameter_missing, result: { message: e.message }
  end
end
```

[⬆️ Voltar ao topo](#índice-)

### Compondo casos de uso

Uma composição encadeia casos de uso de forma que os dados do `Success` de cada step alimentam a entrada do próximo step. Há duas formas de compor: [Flows](#flows) — que cobrem tanto `Micro::Cases.flow(...)` quanto a macro `flow ...` no nível da classe — e [Steps internos](#steps-internos--cadeias-com-resultthen) (a cadeia `Result#then` / `|` dentro de um único `call!`). Qualquer uma das formas pode ser envolvida em uma [Transação](#transações).

#### Flows

Um `Micro::Cases::Flow` é uma composição independente. Construa um com `Micro::Cases.flow([...])` ou com a macro `flow ...` no nível da classe:

```ruby
module Steps
  class ParseTags < Micro::Case
    attribute :tags

    def call!
      if tags.is_a?(String)
        Success result: { tags: tags.split(',').map(&:strip) }
      else
        Failure result: { message: 'tags must be a comma-separated String' }
      end
    end
  end

  class Downcase < Micro::Case::Strict
    attribute :tags
    def call!; Success result: { tags: tags.map(&:downcase) }; end
  end

  class StripHashPrefix < Micro::Case::Strict
    attribute :tags
    def call!; Success result: { tags: tags.map { it.sub(/\A#/, '') } }; end
  end

  class RemoveDuplicates < Micro::Case::Strict
    attribute :tags
    def call!; Success result: { tags: tags.uniq }; end
  end
end

# Usando o construtor a nível de módulo:
DowncaseTags = Micro::Cases.flow([
  Steps::ParseTags,
  Steps::Downcase
])

DowncaseTags.call(tags: 'Ruby, Rails, RUBY').data
# => { tags: ["ruby", "rails", "ruby"] }

# Usando uma classe:
class NormalizeTags < Micro::Case
  flow Steps::ParseTags,
       Steps::Downcase,
       Steps::StripHashPrefix,
       Steps::RemoveDuplicates
end

NormalizeTags
  .call(tags: 42)
  .on_failure { puts it[:message] }
# => "tags must be a comma-separated String"
```

Quando um flow falha, `Result#use_case` aponta para o step responsável:

```ruby
result = NormalizeTags.call(tags: 42)
result.failure?                          # => true
result.use_case.is_a?(Steps::ParseTags)  # => true
```

##### Compondo flows entre si

Flows podem ser steps dentro de outros flows. Misture qualquer um dos três estilos de composição:

```ruby
DowncaseTags           = Micro::Cases.flow([Steps::ParseTags, Steps::Downcase])
DedupedTags            = Micro::Cases.flow([Steps::ParseTags, Steps::RemoveDuplicates])
DowncaseAndDedupedTags = Micro::Cases.flow([DowncaseTags, Steps::RemoveDuplicates])
StrippedAndDeduped     = Micro::Cases.flow([Steps::ParseTags, Steps::StripHashPrefix, Steps::RemoveDuplicates])

DowncaseAndDedupedTags
  .call(tags: 'Ruby, Rails, RUBY')
  .on_success { p it[:tags] } # => ["ruby", "rails"]
```

> Veja [`test/micro/cases/flow/blend_test.rb`](https://github.com/serradura/u-case/blob/main/test/micro/cases/flow/blend_test.rb) para todas as combinações possíveis.

##### Acumulação de dados através de um flow

A saída de `Success` de cada step é mesclada em um hash de atributos corrente, que se torna a entrada do próximo step. Os steps não precisam encadear inputs manualmente — eles apenas declaram o que precisam:

```ruby
module Users
  class FindByEmail < Micro::Case
    attribute :email

    def call!
      user = User.find_by(email:)

      return Success result: { user: } if user

      Failure(:user_not_found)
    end
  end

  class ValidatePassword < Micro::Case::Strict
    attributes :user, :password

    def call!
      return Failure(:user_must_be_persisted) if user.new_record?
      return Failure(:wrong_password)         if user.wrong_password?(password)

      Success result: attributes(:user)
    end
  end

  Authenticate = Micro::Cases.flow([FindByEmail, ValidatePassword])
end

Users::Authenticate
  .call(email: 'somebody@test.com', password: 'password')
  .on_success { sign_in(it[:user]) }
  .on_failure(:wrong_password)  { render status: 401 }
  .on_failure(:user_not_found)  { render status: 404 }
```

`ValidatePassword` declara `:user` como um dos seus atributos mas não recebe ele explicitamente — herda do resultado de sucesso de `FindByEmail`. Esse é o contrato de acumulação: saída → entrada.

##### Inspecionando a execução com `result.transitions`

Cada caso de uso (e cada step interno) contribui com uma entrada para `result.transitions`. Use para debugar, rastrear ou testar a execução de um flow:

```ruby
user_authenticated = Users::Authenticate.call(email: 'rodrigo@test.com', password: '...')

user_authenticated.transitions
# => [
#   {
#     use_case: {
#       class:      Users::FindByEmail,
#       attributes: { email: 'rodrigo@test.com' }
#     },
#     success: { type: :ok, result: { user: #<User ...> } },
#     accessible_attributes: [ :email, :password ]
#   },
#   {
#     use_case: {
#       class:      Users::ValidatePassword,
#       attributes: { user: #<User ...>, password: '...' }
#     },
#     success: { type: :ok, result: { user: #<User ...> } },
#     accessible_attributes: [ :email, :password, :user ]
#   }
# ]
```

Schema:

```ruby
[
  {
    use_case: {
      class:      <Micro::Case>,        # o caso de uso executado
      attributes: <Hash>                # entrada
    },
    [success:, failure:] => {           # saída (um dos dois)
      type:   <Symbol>,                 # :ok / :error / :exception / customizado
      result: <Hash>                    # data
    },
    accessible_attributes: <Array>      # atributos acessíveis neste step
                                        # (cresce a cada sucesso)
  }
]
```

`accessible_attributes` cresce conforme a saída de `Success` de cada step é mesclada nos dados correntes. [`Result#then`](#continuações-dinâmicas-com-resultthen) também contribui com uma transition.

Para desabilitar transitions globalmente (economiza um hash por step), veja [Configuração](#configuração).

##### Compondo um flow que inclui a si mesmo

Uma classe pode usar ela mesma como um step na sua própria declaração de `flow` via `self.call!`:

```ruby
class ParseTagsString < Micro::Case
  attribute :input
  def call!; Success result: { tags: input.split(',').map(&:strip) }; end
end

class JoinTagsArray < Micro::Case
  attribute :tags
  def call!; Success result: { input: tags.join(', ') }; end
end

class CleanTags < Micro::Case
  flow ParseTagsString,
       self.call!,
       JoinTagsArray

  attribute :tags

  def call!
    Success result: { tags: tags.map(&:downcase).uniq }
  end
end

CleanTags.call(input: 'Ruby, RUBY, Rails').data[:input] # => "ruby, rails"
```

Funciona com `Micro::Case::Safe` também — veja [`test/micro/case/safe/with_inner_flow_test.rb`](https://github.com/serradura/u-case/blob/main/test/micro/case/safe/with_inner_flow_test.rb).

#### Steps internos — cadeias com `Result#then`

`Result#then` (e seu alias `|` pipe) é a **terceira forma de compor um flow** do u-case — ao lado de `Micro::Cases.flow(...)` e da macro `flow ...` no nível da classe. Em vez de conectar casos de uso irmãos, você mantém a cadeia _dentro_ do `call!` de um único caso de uso. Cada elo é um método, lambda, ou outra classe de caso de uso; cada elo retorna um `Micro::Case::Result`; os dados de `Success` de cada elo viram os keyword arguments do próximo; cada elo contribui com uma linha em `result.transitions`.

##### Formas aceitas de elo

| Formato do argumento        | Exemplo                                          |
| --------------------------- | ------------------------------------------------ |
| `Symbol` (nome de método)   | `result.then(:strip_title)`                      |
| Objeto `Method` bound       | `result.then(method(:strip_title))`              |
| `Lambda` / `Proc`           | `result.then(-> data { strip_title(**data) })`   |
| Classe de caso de uso       | `result.then(CapitalizeTitle)`                   |
| `Symbol` + Hash de defaults | `result.then(:add, number: 3)`                   |
| Bloco                       | `result.then { \|r\| r.success? ? r[:sum] : 0 }` |

O método conectado **precisa** retornar um `Micro::Case::Result`. Qualquer outra coisa levanta `Micro::Case::Error::UnexpectedResult` (ex. um método que retorna um `Hash` simples é rejeitado com `MyCase#method(:foo) must return an instance of Micro::Case::Result`).

##### Um exemplo mínimo

```ruby
class CapitalizeTitle < Micro::Case
  attribute :title

  def call!
    Success :capitalized, result: { title: title.split.map(&:capitalize).join(' ') }
  end
end

class CreateBlogPost < Micro::Case
  attributes :raw_title, :body

  def call!
    validate_input
      .then(:strip_title)
      .then(:slugify, separator: '-')
      .then(CapitalizeTitle)
  end

  private

  def validate_input
    Kind.of?(String, raw_title, body) ? Success(:valid) : Failure()
  end

  def strip_title
    Success :stripped, result: { title: raw_title.strip }
  end

  def slugify(title:, separator:, **)
    slug = title.downcase.gsub(/[^a-z0-9]+/, separator)
    Success :slugified, result: { title:, slug: }
  end
end

CreateBlogPost.call(raw_title: '  hello world  ', body: 'lorem ipsum').data
# => { title: "Hello World" }
```

Elos baseados em símbolos, métodos e lambdas todos rodam **como o caso de uso hospedeiro**, então eles reportam `class: CreateBlogPost` em `result.transitions`. Só o elo `CapitalizeTitle` (outra classe de caso de uso) contribui com uma transition com `use_case.class` diferente. `accessible_attributes` cresce conforme a saída de `Success` de cada elo é mesclada nos dados correntes — quando `CapitalizeTitle` roda, `slug` também já está acessível upstream.

##### Alias `|` (pipe)

`|` é açúcar sintático para `.then(...)`. O exemplo anterior fica:

```ruby
def call!
  validate_input | :strip_title | :slugify | CapitalizeTitle
end
```

As duas formas produzem o mesmo `result.data` e o mesmo `result.transitions`.

> **Cadeias estilo Elixir com `it` (Ruby ≥ 3.4):** o Ruby 3.4 expõe `it` como o primeiro parâmetro implícito do corpo de um bloco/lambda, então uma cadeia pode ficar quase idêntica ao `|>` do Elixir. Cada lambda recebe o hash de dados acumulado como `it` e ainda precisa terminar em `Success(...)` / `Failure(...)`:
>
> ```ruby
> def call!
>   validate_something \
>     | -> { do_something_with(**it) } \
>     | -> { and_another_thing_with(**it) }
> end
> ```
>
> No Ruby 2.7 – 3.3 (onde `it` é só um identificador indefinido), use a forma explícita `->(data) { do_something_with(**data) }`.

##### Formas Lambda / `Method`

Lambdas (e objetos `Method` bound) recebem os dados acumulados **posicionalmente** como um único Hash:

```ruby
def call!
  validate_input
    .then(method(:strip_title))
    .then(->(data) { slugify(**data, separator: '-') })
    .then(CapitalizeTitle)
end
```

##### `Failure` interrompe a cadeia

Retornar `Failure(...)` de qualquer elo interrompe o resto da cadeia imediatamente — exatamente como um step em um flow top-level retornando uma falha. Os `.then(...)` / `|` restantes não são invocados; o `result` final é a falha.

##### Usando um caso com steps internos dentro de um flow externo

Um caso de uso que compõe internamente é só um caso de uso, então cabe em qualquer flow:

```ruby
PublishWorkflow = Micro::Cases.flow([
  AuthorizePublisher,
  CreateBlogPost,     # ← usa .then(:método) internamente
  EnqueueIndexingJob
])
```

As transitions internas do hospedeiro são intercaladas com as transitions folha do flow externo na ordem de execução. Se `CreateBlogPost` produz 4 transitions internas e o flow externo tem 2 outros steps folha, o `result.transitions` final tem 6 entradas.

##### Persistência sem transação

Por padrão — quando nem a classe hospedeira nem o flow externo usam `transaction: true` — steps internos se comportam como qualquer outro código em `call!`: efeitos colaterais de elos anteriores **persistem** mesmo se um elo posterior retornar `Failure`. A cadeia para, mas o que já foi escrito fica escrito:

```ruby
class CreateUserWithProfileInline < Micro::Case
  attributes :name, :info

  def call!
    create_user.then(:create_profile)
  end

  private

  def create_user
    user = User.create(name:)
    Success result: { user: }
  end

  def create_profile(user:, **)
    profile = UserProfile.create(user_id: user.id, info:)
    return Failure(:invalid_profile) if profile.errors.any?

    Success result: { user:, profile: }
  end
end

CreateUserWithProfileInline.call(name: 'Rodrigo', info: '')
# create_user já fez INSERT na linha do user; create_profile falhou.
# user está persistido; profile não. Sem rollback automático.
```

Para reverter os writes parciais, envolva a cadeia em uma [transação](#transações).

#### Transações

O `u-case` traz dois helpers complementares para envolver trabalho em uma `ActiveRecord::Base.transaction`. Ambos são opt-in — `active_record` **não** é requerido pela gem, então você carrega o ActiveRecord por conta própria (aplicações Rails já fazem isso).

##### `transaction { ... }` inline dentro do `call!`

`Micro::Case#transaction` (e `Micro::Case::Safe#transaction`) é um helper de instância privado que envolve um bloco em uma transação de banco e dispara `ActiveRecord::Rollback` sempre que o resultado do bloco é um `Failure`. O resultado original é retornado de qualquer forma, então você pode continuar encadeando com `Result#then`:

```ruby
class CreateUserWithAProfile < Micro::Case
  def call!
    transaction {
      call(CreateUser).then(CreateUserProfile)
    }
  end
end
```

Se o bloco retorna uma falha (ou levanta), todas as linhas escritas dentro do bloco são revertidas. O helper aceita `with:` para escolher a classe ActiveRecord na qual `.transaction` é aberta — útil para aplicações Rails com multi-database (`ApplicationRecord`, `AnalyticsRecord`, `BillingRecord`, …):

```ruby
class CreateAuditEntry < Micro::Case
  def call!
    transaction(with: AnalyticsRecord) {
      call(WriteAuditLog).then(BumpCounter)
    }
  end
end
```

Quando `with:` é omitido, o helper cai para a macro de classe (`transaction with: …`) e depois para o callback global de padrão.

> Qualquer classe passada via `with:` (helper inline, macro de classe ou kwarg de flow) **precisa ser uma subclasse de `ActiveRecord::Base`**. Classes que não sejam AR são rejeitadas com `ArgumentError`.
>
> **Retrocompatibilidade:** a forma posicional pré-5.6.0 `transaction(:activerecord) { ... }` continua funcionando como alias de `transaction { ... }`; qualquer outro valor posicional levanta `ArgumentError`.

##### `transaction with: …` — declarando o padrão para um caso

Uma macro de classe permite que um caso declare qual classe ActiveRecord deve dona das transações dele, então nem o helper inline nem nenhum flow que envolve o caso precisam soletrar isso. A declaração é herdada:

```ruby
class ApplicationUseCase < Micro::Case
  transaction with: ApplicationRecord
end

class CreateUserWithAProfile < ApplicationUseCase
  flow(transaction: true, steps: [CreateUser, CreateUserProfile])
  # transaction: true resolve para ApplicationRecord (herdado).
end

class BillingCase < ApplicationUseCase
  transaction with: BillingRecord
  # sobrescreve a declaração herdada para este ramo da árvore
end
```

##### Transações no nível do flow

Passe `transaction:` junto com `steps:` para envolver um flow inteiro em uma única transação. Se qualquer step retorna uma falha (ou levanta, num `safe_flow`), todo write de banco feito durante o flow é revertido. Três formas:

```ruby
# Usa a macro de classe (se a classe hospedeira declarou uma) ou o padrão global.
Micro::Cases.flow(transaction: true, steps: [CreateUser, CreateUserProfile])

# Escolhe uma classe ActiveRecord explícita só para este flow — mesmo vocabulário `with:`.
Micro::Cases.flow(transaction: { with: AnalyticsRecord }, steps: [
  WriteAuditLog,
  BumpCounter
])

# safe_flow reverte em falhas E em exceções inesperadas.
Micro::Cases.safe_flow(transaction: { with: ApplicationRecord }, steps: [
  CreateUser,
  CreateUserProfile
])

# Forma a nível de classe
class CreateUserWithAProfile < Micro::Case
  flow(transaction: true, steps: [CreateUser, CreateUserProfile])
end
```

Para aninhar um flow transacional dentro de outro flow, envolva ele em uma classe de caso de uso — `Micro::Cases.flow([...])` achata instâncias de `Flow` passadas como steps, mas **não** achata classes:

```ruby
class CreateUserAndProfile < Micro::Case
  flow(transaction: true, steps: [CreateUser, CreateUserProfile])
end

SignUpFlow = Micro::Cases.flow([
  NormalizeParams,
  ValidatePassword,
  CreateUserAndProfile,
  EnqueueIndexingJob
])
```

Se `transaction: true` for usado enquanto `ActiveRecord::Base` não está carregado, o flow levanta `Micro::Cases::Error::TransactionAdapterMissing` na primeira chamada para que a configuração errada apareça imediatamente. Passar `transaction: { with: SomeClass }` pula essa checagem — `SomeClass` é confiado a responder a `.transaction`.

##### Padrão global — `config.default_transaction_class { … }`

Para aplicações Rails que usam um único record abstrato (`ApplicationRecord`), configure-o uma vez em um initializer em vez de declarar em cada caso ou flow:

```ruby
# config/initializers/u_case.rb
Micro::Case.config do |config|
  config.default_transaction_class { ApplicationRecord }
end
```

O callback (bloco ou lambda) é invocado **toda vez** que uma transação abre — sem memoização — então o valor de retorno pode depender de estado em runtime (roteamento por tenant, etc.). O padrão é `-> { ::ActiveRecord::Base }`.

Ordem de resolução, quando uma transação abre:

1. **Override no local de chamada** — `transaction: { with: X }` em um kwarg de flow, ou `transaction(with: X) { ... }` no helper inline.
2. **Macro `transaction with: X` da classe hospedeira** (caminha pelos ancestrais).
3. **`Micro::Case.config.default_transaction_class.call`** — o callback global (padrão é `ActiveRecord::Base`).

Uma atribuição não-callable em `default_transaction_class=` levanta `ArgumentError` na hora da configuração para que typos como `config.default_transaction_class = 'ApplicationRecord'` falhem barulhentamente em vez de crasharem na primeira transação.

##### Flows com steps internos sob transações

[Steps internos](#steps-internos--cadeias-com-resultthen) — a forma `Result#then(:symbol)` / `|` construída inline dentro de um único `call!` — são um flow _interno_. Por padrão eles **não têm rollback transacional**: efeitos colaterais de elos `.then(:method)` anteriores persistem mesmo quando um elo posterior retorna `Failure`.

Duas formas naturais de dar rollback:

**1. Envolva o caso hospedeiro em um flow `transaction: true`.** Recomendado uma vez que o caso hospedeiro está dentro de um pipeline maior. A transação cobre a chamada inteira do flow, então uma `Failure` _em qualquer lugar_ — incluindo de qualquer elo interno `.then(:method)` — reverte todo write de banco:

```ruby
class CreateUserWithProfileInline < Micro::Case
  attributes :name, :info

  def call!
    create_user.then(:create_profile)
  end

  private

  def create_user
    user = User.create(name:)
    Success result: { user: }
  end

  def create_profile(user:, **)
    profile = UserProfile.create(user_id: user.id, info:)
    return Failure(:invalid_profile) if profile.errors.any?

    Success result: { user:, profile: }
  end
end

SignUp = Micro::Cases.flow(transaction: true, steps: [
  NormalizeParams,
  CreateUserWithProfileInline,   # ← falha interna agora reverte
  EnqueueIndexingJob
])
```

Se `create_profile` retorna `Failure(:invalid_profile)`, a linha de `User` inserida antes é revertida como parte da mesma `ActiveRecord::Base.transaction`. O resultado ainda surfaceia o tipo de falha e as transitions parciais, mas nenhuma linha fica para trás.

**2. Use o helper inline `transaction { ... }`** para escopar o rollback a um único `call!` sem envolver um flow externo:

```ruby
class CreateUserWithProfileInline < Micro::Case
  def call!
    transaction {
      create_user.then(:create_profile)
    }
  end
end
```

As duas abordagens compõem. Se `CreateUserWithProfileInline` (usando `transaction { ... }` inline) está dentro de um flow externo `transaction: true`, o ActiveRecord junta a transação interna na externa por padrão — uma falha externa reverte os writes da interna também.

##### Observações de comportamento

- **O resultado não é afetado.** `transaction: true` só afeta efeitos colaterais de banco. `result.data`, `result.type`, `result.transitions` e `result.accessible_attributes` são idênticos aos de um flow não-transacional equivalente.
- **Instâncias de `Flow` são achatadas.** `Micro::Cases.flow([inner_flow, Other])` achata `inner_flow` para seus steps folha — uma instância transacional de `Flow` passada assim **perde sua transação**. Envolva flows transacionais reutilizáveis em uma classe de caso de uso para preservar a transação quando aninhados.
- **Transações aninhadas se juntam à externa.** O ActiveRecord junta elas por padrão (sem `requires_new: true`). Uma falha em qualquer lugar na cadeia reverte **tudo** escrito dentro da transação mais externa.
- **Um externo não-transacional commita o interno.** Se o flow externo não é transacional e o flow transacional interno sucede, os writes do interno commitam no final do step interno. Uma falha em um step posterior (não-transacional) **não** desfaz esses writes.
- **`Micro::Cases.flow(transaction: true, ...)` puro relança exceções.** A transação ainda reverte, mas quem chamou tem que dar `rescue`. Use `Micro::Cases.safe_flow(transaction: true, ...)` (ou a forma a nível de classe com `Micro::Case::Safe`) para capturar a exceção como uma falha `:exception`.

[⬆️ Voltar ao topo](#índice-)

## Configuração

`Micro::Case.config` expõe as toggles da gem. Configure uma vez — tipicamente em um initializer do Rails:

```ruby
Micro::Case.config do |config|
  # Falha automaticamente casos de uso em erros de validação do ActiveModel.
  config.enable_activemodel_validation = false

  # Símbolo de tipo usado pela auto-falha quando a validação do ActiveModel
  # rejeita um atributo (compartilhado com a falha de rejeição de accept:/reject:).
  # Padrão é :invalid_attributes.
  config.set_activemodel_validation_errors_failure = :invalid_attributes

  # Registra Micro::Case::Result#transitions em cada step do flow.
  # Configure para false para economizar a alocação do hash por step em hot paths.
  config.enable_transitions = true

  # Proíbe as APIs Safe para impor uma única convenção de tratamento de
  # exceções (apenas `rescue` dentro dos casos de uso). Quando true, os itens
  # abaixo levantam Micro::Case::Error::SafeFeaturesDisabled:
  #   - herdar de Micro::Case::Safe
  #   - chamar Micro::Cases.safe_flow(...)
  #   - chamar Micro::Case::Result#on_exception
  config.disable_safe_features = false

  # Pula os checks internos de argumento/contrato da gem para um pequeno ganho
  # de performance em produção uma vez que seu test suite tenha exercitado os
  # code paths. Usos incorretos vão aparecer como erros downstream em vez dos
  # erros curados da gem.
  config.disable_runtime_checks = false

  # A classe ActiveRecord usada por `transaction: true`. Passe um bloco (ou lambda).
  # O padrão é `-> { ::ActiveRecord::Base }`. Sobrescreva para usar um record
  # abstrato por aplicação como ApplicationRecord.
  config.default_transaction_class { ApplicationRecord }
end
```

Todos os checks internos vivem em `Micro::Case::Check::Enabled` (o padrão). Ativar `disable_runtime_checks = true` troca `Micro::Case.check` para `Micro::Case::Check::Disabled`, cujos métodos são no-ops — as validações em si param de rodar a cada chamada.

[⬆️ Voltar ao topo](#índice-)

## Performance

Em benchmarks contra abstrações comparáveis, `Micro::Case` é o mais rápido depois do `Dry::Monads`:

| Gem / Abstração        | Success (i/s) | Failure (i/s) |
| ---------------------- | ------------: | ------------: |
| Dry::Monads            |     315,635.1 |     135,386.9 |
| **Micro::Case**        |      75,837.7 |      73,489.3 |
| Interactor             |      59,745.5 |      27,037.0 |
| Trailblazer::Operation |      28,423.9 |      29,016.4 |
| Dry::Transaction       |      10,130.9 |       8,988.6 |

Para flows, o alias `|` pipe é o estilo de composição mais rápido:

| Estilo de composição         |      Success |      Failure |
| ---------------------------- | -----------: | -----------: |
| `Result#\|` (pipe)           |     80,936.2 |     78,280.4 |
| `Micro::Cases.flow(...)`     |     same-ish |     same-ish |
| `Result#then`                |     same-ish |     same-ish |
| Classe com `flow` interno    | 1.72× slower | 1.68× slower |
| Classe que inclui a si mesma | 1.93× slower | 1.87× slower |
| `Interactor::Organizer`      | 3.33× slower | 3.22× slower |

> `Dry::Monads`, `Dry::Transaction` e `Trailblazer::Operation` não têm uma feature equivalente a flow e ficam fora da tabela de flow.

### Executando os benchmarks

```sh
# Casos de uso
ruby benchmarks/perfomance/use_case/success_results.rb
ruby benchmarks/perfomance/use_case/failure_results.rb

# Flows
ruby benchmarks/perfomance/flow/success_results.rb
ruby benchmarks/perfomance/flow/failure_results.rb
```

Memory profiling:

```sh
./benchmarks/memory/use_case/success/with_transitions/analyze.sh
./benchmarks/memory/use_case/success/without_transitions/analyze.sh
./benchmarks/memory/flow/success/with_transitions/analyze.sh
./benchmarks/memory/flow/success/without_transitions/analyze.sh
```

### Desabilitando os checks em runtime

Configure `disable_runtime_checks = true` para um pequeno ganho de alguns por cento em produção uma vez que seu test suite tenha exercitado os code paths:

```ruby
Micro::Case.config { it.disable_runtime_checks = true }
```

Os ganhos medidos (veja [`benchmarks/perfomance/runtime_checks/compare.rb`](https://github.com/serradura/u-case/blob/main/benchmarks/perfomance/runtime_checks/compare.rb)) dependem do JIT: dentro do ruído no Ruby puro, ~3–5% no Ruby 3.2 +YJIT, ~4–7% no Ruby 4.0 +PRISM.

### Comparações

Implementações lado a lado do mesmo caso de uso em outras bibliotecas:

- [Interactor](https://github.com/serradura/u-case/blob/main/comparisons/interactor.rb)
- [u-case](https://github.com/serradura/u-case/blob/main/comparisons/u-case.rb)

[⬆️ Voltar ao topo](#índice-)

## Exemplos

### Um flow completo de cadastro

Três casos de uso compostos em um flow transacional, usando validação `accept:`, contratos de resultado e hooks:

```ruby
class NormalizeParams < Micro::Case
  attribute :params, accept: Hash

  results do |on|
    on.success(result: [:name, :email])
    on.failure(:invalid_params)
  end

  def call!
    name  = params[:name].to_s.strip
    email = params[:email].to_s.strip.downcase

    return Failure(:invalid_params) if name.empty? || email.empty?

    Success result: { name:, email: }
  end
end

class CreateUser < Micro::Case
  attributes :name, :email

  results do |on|
    on.success(result: [:user])
    on.failure(:invalid_user)
  end

  def call!
    user = User.create(name:, email:)

    return Failure(:invalid_user, result: { errors: user.errors }) if user.errors.any?

    Success result: { user: }
  end
end

class CreateProfile < Micro::Case
  attributes :user

  results do |on|
    on.success(result: [:profile])
    on.failure(:invalid_profile)
  end

  def call!
    profile = Profile.create(user_id: user.id)

    return Failure(:invalid_profile, result: { errors: profile.errors }) if profile.errors.any?

    Success result: { profile: }
  end
end

SignUp = Micro::Cases.flow(transaction: true, steps: [
  NormalizeParams,
  CreateUser,
  CreateProfile
])

SignUp
  .call(params: { name: 'Ada', email: 'ADA@EXAMPLE.com' })
  .on_success                   { render json: { user_id: it[:user].id } }
  .on_failure(:invalid_params)  { render status: 422 }
  .on_failure(:invalid_user)    { render status: 422, json: { errors: it[:errors] } }
  .on_failure(:invalid_profile) { render status: 422, json: { errors: it[:errors] } }
```

Se `CreateProfile` falha, a linha de `User` inserida por `CreateUser` é revertida — esse é o `transaction: true` fazendo seu trabalho. O resultado surfaceia `:invalid_profile`, o hook dispara, e o banco fica limpo.

### Mais exemplos

- **[Flow de criação de usuários](https://github.com/serradura/u-case/blob/main/examples/users_creation)** — sanitiza, valida, persiste; demonstra todos os estilos de composição.
- **[Aplicação Rails (API)](https://github.com/serradura/from-fat-controllers-to-use-cases)** — arquiteturas diferentes em commits diferentes; o último usa `Micro::Case` para a regra de negócio.
- **[Calculadora CLI](https://github.com/serradura/u-case/tree/main/examples/calculator)** — Rake tasks demonstrando manipulação de input do usuário e fluxo de controle baseado em tipos de falha.
- **[Capturando exceções](https://github.com/serradura/u-case/blob/main/examples/rescuing_exceptions.rb)** — padrões para tratamento de exceções dentro de casos de uso.

[⬆️ Voltar ao topo](#índice-)

## Indo além com `u-attributes`

As macros `attribute` / `attributes` do `Micro::Case` vêm do [`u-attributes`](https://github.com/serradura/u-attributes), e todo recurso que aquela gem suporta está disponível em todo caso de uso. Dois padrões que vale conhecer — **ambos requerem [`u-attributes >= 3.1`](https://github.com/serradura/u-attributes)**:

### Atributos aninhados (forma com bloco)

Declare um atributo que tem atributos por dentro — útil quando seu input é um objeto estruturado em vez de um hash plano. O `accept:` nos atributos internos ainda participa da falha `:invalid_attributes` do pai:

```ruby
class CreateOrder < Micro::Case
  attribute :id, accept: Integer

  attribute :customer do
    attribute :name,  accept: String
    attribute :email, accept: String
  end

  def call!
    Success result: { order: Order.create!(id:, customer_id: customer.id) }
  end
end

CreateOrder
  .call(id: 42, customer: { name: 'Ada', email: 'ada@example.com' })
  .success? # => true

CreateOrder
  .call(id: 42, customer: { name: 42, email: 'ada@example.com' })
  .type     # => :invalid_attributes
```

O hash aninhado é acessível como `customer.name`, `customer.email`.

### Aceitando outra classe de atributos

`accept:` pode apontar para outra classe — hashes que chegam são automaticamente convertidos em instâncias dela:

```ruby
class CreateProfile < Micro::Case
  Address = Micro::Attributes.new do
    attribute :city,   accept: String
    attribute :postal, accept: String
  end

  attribute :name,    accept: String
  attribute :address, accept: Address

  def call!
    Success result: { profile: Profile.create!(name:, address: address.to_h) }
  end
end

CreateProfile.call(
  name: 'Rodrigo',
  address: { city: 'Rio', postal: '20000-000' }
)
# => Success — `address` é uma instância de Address dentro de `call!`
```

Para defaults, `allow_nil:`, validators customizados e o resto do conjunto de recursos, veja o README do [`u-attributes`](https://github.com/serradura/u-attributes).

[⬆️ Voltar ao topo](#índice-)

## Desenvolvimento

Depois de clonar o repo, rode `bin/setup` para instalar as dependências e atualizar os appraisals. Então `bundle exec rake test` roda a suíte padrão, `bundle exec appraisal <nome> rake test` roda um appraisal específico do Rails (veja `Appraisals`), e `bundle exec rake matrix` roda a matriz local completa para o Ruby ativo. `bin/console` abre um prompt interativo.

Para instalar na sua máquina, rode `bundle exec rake install`. Para lançar uma nova versão, atualize `lib/micro/case/version.rb` e então rode `bundle exec rake release` (cria a tag git, faz push dos commits e tags, e dá push do `.gem` para o [rubygems.org](https://rubygems.org)).

## Contribuindo

Bug reports e pull requests são bem-vindos no GitHub em https://github.com/serradura/u-case. Este projeto pretende ser um espaço seguro e acolhedor para colaboração, e os contribuidores devem aderir ao código de conduta do [Contributor Covenant](https://contributor-covenant.org).

## Licença

Disponível como open source sob os termos da [MIT License](https://opensource.org/licenses/MIT).

## Código de conduta

Todos que interagem com a codebase, issue trackers, salas de chat e listas de email do projeto Micro::Case devem seguir o [código de conduta](https://github.com/serradura/u-case/blob/main/CODE_OF_CONDUCT.md).
