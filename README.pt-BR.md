<p align="center">
  <img src="./assets/ucase_logo_v1.png" alt="u-case - Represent use cases in a simple and powerful way while writing modular, expressive and sequentially logical code.">

  <p align="center"><i> Represente casos de uso de forma simples e poderosa ao escrever código modular, expressivo e sequencialmente lógico.</i></p>
  <br>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/ruby-2.2+-ruby.svg?colorA=99004d&colorB=cc0066" alt="Ruby">

  <a href="https://rubygems.org/gems/u-case">
    <img alt="Gem" src="https://img.shields.io/gem/v/u-case.svg?style=flat-square">
  </a>

  <a href="https://travis-ci.com/serradura/u-case">
    <img alt="Build Status" src="https://travis-ci.com/serradura/u-case.svg?branch=main">
  </a>

  <a href="https://codeclimate.com/github/serradura/u-case/maintainability">
    <img alt="Maintainability" src="https://api.codeclimate.com/v1/badges/5c3c8ad1b0b943f88efd/maintainability">
  </a>

  <a href="https://codeclimate.com/github/serradura/u-case/test_coverage">
    <img alt="Test Coverage" src="https://api.codeclimate.com/v1/badges/5c3c8ad1b0b943f88efd/test_coverage">
  </a>
</p>

Principais objetivos deste projeto:
1. Fácil de usar e aprender ( entrada **>>** processamento **>>** saída ).
2. Promover imutabilidade (transformar dados ao invés de modificar) e integridade de dados.
3. Nada de callbacks (ex: before, after, around) para evitar indireções no código que possam comprometer o estado e entendimento dos fluxos da aplicação.
4. Resolver regras de negócio complexas, ao permitir uma composição de casos de uso (criação de fluxos).
5. Ser rápido e otimizado (verifique a [seção de benchmarks](#benchmarks)).

> **Nota:** Verifique o repo https://github.com/serradura/from-fat-controllers-to-use-cases para ver uma aplicação Ruby on Rails que utiliza esta gem para resolver as regras de negócio.

## Documentação <!-- omit in toc -->

Versão    | Documentação
--------- | -------------
4.0.0     | https://github.com/serradura/u-case/blob/main/README.md
3.1.0     | https://github.com/serradura/u-case/blob/v3.x/README.md
2.6.0     | https://github.com/serradura/u-case/blob/v2.x/README.md
1.1.0     | https://github.com/serradura/u-case/blob/v1.x/README.md

## Índice <!-- omit in toc -->
- [Compatibilidade](#compatibilidade)
- [Dependências](#dependências)
- [Instalação](#instalação)
- [Uso](#uso)
  - [`Micro::Case` - Como definir um caso de uso?](#microcase---como-definir-um-caso-de-uso)
  - [`Micro::Case::Result` - O que é o resultado de um caso de uso?](#microcaseresult---o-que-é-o-resultado-de-um-caso-de-uso)
    - [O que são os tipos de resultados?](#o-que-são-os-tipos-de-resultados)
    - [Como definir tipos customizados de resultados?](#como-definir-tipos-customizados-de-resultados)
    - [É possível definir um tipo sem definir os dados do resultado?](#é-possível-definir-um-tipo-sem-definir-os-dados-do-resultado)
    - [Como utilizar os hooks dos resultados?](#como-utilizar-os-hooks-dos-resultados)
    - [Por que o hook sem um tipo definido expõe o próprio resultado?](#por-que-o-hook-sem-um-tipo-definido-expõe-o-próprio-resultado)
      - [Usando decomposição para acessar os dados e tipo do resultado](#usando-decomposição-para-acessar-os-dados-e-tipo-do-resultado)
    - [O que acontece se um hook de resultado for declarado múltiplas vezes?](#o-que-acontece-se-um-hook-de-resultado-for-declarado-múltiplas-vezes)
    - [Como usar o método `Micro::Case::Result#then`?](#como-usar-o-método-microcaseresultthen)
      - [O que acontece quando um `Micro::Case::Result#then` recebe um bloco?](#o-que-acontece-quando-um-microcaseresultthen-recebe-um-bloco)
      - [Como fazer injeção de dependência usando este recurso?](#como-fazer-injeção-de-dependência-usando-este-recurso)
  - [`Micro::Cases::Flow` - Como compor casos de uso?](#microcasesflow---como-compor-casos-de-uso)
    - [É possível compor um fluxo com outros fluxos?](#é-possível-compor-um-fluxo-com-outros-fluxos)
    - [É possível que um fluxo acumule sua entrada e mescle cada resultado de sucesso para usar como argumento dos próximos casos de uso?](#é-possível-que-um-fluxo-acumule-sua-entrada-e-mescle-cada-resultado-de-sucesso-para-usar-como-argumento-dos-próximos-casos-de-uso)
    - [Como entender o que aconteceu durante a execução de um flow?](#como-entender-o-que-aconteceu-durante-a-execução-de-um-flow)
      - [`Micro::Case::Result#transitions` schema](#microcaseresulttransitions-schema)
      - [É possível desabilitar o `Micro::Case::Result#transitions`?](#é-possível-desabilitar-o-microcaseresulttransitions)
    - [É possível declarar um fluxo que inclui o próprio caso de uso?](#é-possível-declarar-um-fluxo-que-inclui-o-próprio-caso-de-uso)
  - [`Micro::Case::Strict` - O que é um caso de uso estrito?](#microcasestrict---o-que-é-um-caso-de-uso-estrito)
  - [`Micro::Case::Safe` - Existe algum recurso para lidar automaticamente com exceções dentro de um caso de uso ou fluxo?](#microcasesafe---existe-algum-recurso-para-lidar-automaticamente-com-exceções-dentro-de-um-caso-de-uso-ou-fluxo)
    - [`Micro::Case::Result#on_exception`](#microcaseresulton_exception)
    - [`Micro::Cases::Safe::Flow`](#microcasessafeflow)
    - [`Micro::Case::Result#on_exception`](#microcaseresulton_exception-1)
  - [`u-case/with_activemodel_validation` - Como validar os atributos do caso de uso?](#u-casewith_activemodel_validation---como-validar-os-atributos-do-caso-de-uso)
    - [Se eu habilitei a validação automática, é possível desabilitá-la apenas em casos de uso específicos?](#se-eu-habilitei-a-validação-automática-é-possível-desabilitá-la-apenas-em-casos-de-uso-específicos)
    - [`Kind::Validator`](#kindvalidator)
- [`Micro::Case.config`](#microcaseconfig)
- [Benchmarks](#benchmarks)
  - [`Micro::Case`](#microcase)
    - [Success results](#success-results)
    - [Failure results](#failure-results)
  - [`Micro::Cases::Flow`](#microcasesflow)
  - [Execuntando os benchmarks](#execuntando-os-benchmarks)
    - [Performance (Benchmarks IPS)](#performance-benchmarks-ips)
    - [Memory profiling](#memory-profiling)
  - [Comparações](#comparações)
- [Exemplos](#exemplos)
  - [1️⃣ Criação de usuários](#1️⃣-criação-de-usuários)
  - [2️⃣ Rails App (API)](#2️⃣-rails-app-api)
  - [3️⃣ CLI calculator](#3️⃣-cli-calculator)
  - [4️⃣ Interceptando exceções dentro dos casos de uso](#4️⃣-interceptando-exceções-dentro-dos-casos-de-uso)
- [Desenvolvimento](#desenvolvimento)
- [Contribuindo](#contribuindo)
- [Licença](#licença)
- [Código de conduta](#código-de-conduta)

## Compatibilidade

| u-case         | branch  | ruby     |  activemodel  | u-attributes |
| -------------- | ------- | -------- | ------------- | ------------ |
| 4.0.0          | main    | >= 2.2.0 | >= 3.2, < 6.1 |       ~> 2.0 |
| 3.1.0          | v3.x    | >= 2.2.0 | >= 3.2, < 6.1 |       ~> 1.1 |
| 2.6.0          | v2.x    | >= 2.2.0 | >= 3.2, < 6.1 |       ~> 1.1 |
| 1.1.0          | v1.x    | >= 2.2.0 | >= 3.2, < 6.1 |       ~> 1.1 |

> Nota: O activemodel é uma dependência opcional, esse módulo que [pode ser habilitado](#u-casewith_activemodel_validation---como-validar-os-atributos-do-caso-de-uso) para validar os atributos dos casos de uso.

## Dependências

1. Gem [`kind`](https://github.com/serradura/kind).

    Sistema de tipos simples (em runtime) para Ruby.

    É usado para validar os inputs de alguns métodos do u-case, além de expor um validador de tipos através do [`activemodel validation`](https://github.com/serradura/kind#kindvalidator-activemodelvalidations) ([veja como habilitar]((#u-casewith_activemodel_validation---how-to-validate-use-case-attributes))). Por fim, ele também expõe dois verificadores de tipo: [`Kind::Of::Micro::Case`, `Kind::Of::Micro::Case::Result`](https://github.com/serradura/kind#registering-new-custom-type-checker).
2. [`u-attributes`](https://github.com/serradura/u-attributes) gem.

    Essa gem permite definir atributos de leitura (read-only), ou seja, os seus objetos só terão getters para acessar os dados dos seus atributos.
    Ela é usada para definir os atributos dos casos de uso.

## Instalação

Adicione essa linha ao Gemfile da sua aplicação:

```ruby
gem 'u-case', '~> 3.1.0'
```

E então execute:

    $ bundle

Ou instale manualmente:

    $ gem install u-case

## Uso

### `Micro::Case` - Como definir um caso de uso?

```ruby
class Multiply < Micro::Case
  # 1. Defina o input como atributos
  attributes :a, :b

  # 2. Defina o método `call!` com a regra de negócio
  def call!

    # 3. Envolva o resultado do caso de uso com os métodos `Success(result: *)` ou `Failure(result: *)`
    if a.is_a?(Numeric) && b.is_a?(Numeric)
      Success result: { number: a * b }
    else
      Failure result: { message: '`a` and `b` attributes must be numeric' }
    end
  end
end

#===========================#
# Executando um caso de uso #
#===========================#

# Resultado de sucesso

result = Multiply.call(a: 2, b: 2)

result.success? # true
result.data     # { number: 4 }

# Resultado de falha

bad_result = Multiply.call(a: 2, b: '2')

bad_result.failure? # true
bad_result.data     # { message: "`a` and `b` attributes must be numeric" }

# Nota:
# ----
# O resultado de um Micro::Case.call é uma instância de Micro::Case::Result
```

[⬆️ Voltar para o índice](#índice-)

### `Micro::Case::Result` - O que é o resultado de um caso de uso?

Um `Micro::Case::Result` armazena os dados de output de um caso de uso. Esses são seus métodos:
- `#success?` retorna `true` se for um resultado de sucesso.
- `#failure?` retorna `true` se for um resultado de falha.
- `#use_case` retorna o caso de uso responsável pelo resultado. Essa funcionalidade é útil para lidar com falhas em flows (esse tópico será abordado mais a frente).
- `#type` retorna um Symbol que dá significado ao resultado, isso é útil para declarar diferentes tipos de falha e sucesso.
- `#data` os dados do resultado (um `Hash`).
- `#[]` e `#values_at` são atalhos para acessar as propriedades do `#data`.
- `#key?` retorna `true` se a chave estiver present no `#data`.
- `#value?` retorna `true` se o valor estiver present no `#data`.
- `#slice` retorna um novo `Hash` que inclui apenas as chaves fornecidas. Se as chaves fornecidas não existirem, um `Hash` vazio será retornado.
- `#on_success` or `#on_failure` são métodos de hooks que te auxiliam a definir o fluxo da aplicação.
- `#then` este método permite aplicar novos casos de uso ao resultado atual se ele for sucesso. A ideia dessa feature é a criação de fluxos dinâmicos.
- `#transitions` retorna um array com todas as transformações que um resultado [teve durante um flow](#como-entender-o-que-aconteceu-durante-a-execução-de-um-flow).

> **Nota:** por conta de retrocompatibilidade, você pode usar o método `#value` como um alias para o método `#data`.

[⬆️ Voltar para o índice](#índice-)

#### O que são os tipos de resultados?

Todo resultado tem um tipo (`#type`), e estes são os valores padrões:
- `:ok` em casos de sucesso;
- `:error` ou `:exception` em casos de falhas.

```ruby
class Divide < Micro::Case
  attributes :a, :b

  def call!
    if invalid_attributes.empty?
      Success result: { number: a / b }
    else
      Failure result: { invalid_attributes: invalid_attributes }
    end
  rescue => exception
    Failure result: exception
  end

  private def invalid_attributes
    attributes.select { |_key, value| !value.is_a?(Numeric) }
  end
end

# Resultado de sucesso

result = Divide.call(a: 2, b: 2)

result.type     # :ok
result.data     # { number: 1 }
result.success? # true
result.use_case # #<Divide:0x0000 @__attributes={"a"=>2, "b"=>2}, @a=2, @b=2, @__result=...>

# Resultado de falha (type == :error)

bad_result = Divide.call(a: 2, b: '2')

bad_result.type     # :error
bad_result.data     # { invalid_attributes: { "b"=>"2" } }
bad_result.failure? # true
bad_result.use_case # #<Divide:0x0000 @__attributes={"a"=>2, "b"=>"2"}, @a=2, @b="2", @__result=...>

# Resultado de falha (type == :exception)

err_result = Divide.call(a: 2, b: 0)

err_result.type     # :exception
err_result.data     # { exception: <ZeroDivisionError: divided by 0> }
err_result.failure? # true
err_result.use_case # #<Divide:0x0000 @__attributes={"a"=>2, "b"=>0}, @a=2, @b=0, @__result=#<Micro::Case::Result:0x0000 @use_case=#<Divide:0x0000 ...>, @type=:exception, @value=#<ZeroDivisionError: divided by 0>, @success=false>

# Nota:
# ----
# Toda instância de Exception será envolvida pelo método
# Failure(result: *) que receberá o tipo `:exception` ao invés de `:error`.
```

[⬆️ Voltar para o índice](#índice-)

#### Como definir tipos customizados de resultados?

Resposta: Use um `Symbol` com argumento dos métodos `Success()`, `Failure()` e declare o `result:` keyword para definir os dados do resultado.

```ruby
class Multiply < Micro::Case
  attributes :a, :b

  def call!
    if a.is_a?(Numeric) && b.is_a?(Numeric)
      Success result: { number: a * b }
    else
      Failure :invalid_data, result: {
        attributes: attributes.reject { |_, input| input.is_a?(Numeric) }
      }
    end
  end
end

# Resultado de sucesso

result = Multiply.call(a: 3, b: 2)

result.type     # :ok
result.data     # { number: 6 }
result.success? # true

# Resultado de falha

bad_result = Multiply.call(a: 3, b: '2')

bad_result.type     # :invalid_data
bad_result.data     # { attributes: {"b"=>"2"} }
bad_result.failure? # true
```

[⬆️ Voltar para o índice](#índice-)

#### É possível definir um tipo sem definir os dados do resultado?

Resposta: Sim, é possível. Mas isso terá um comportamento especial por conta dos dados do resultado ser um hash com o tipo definido como chave e `true` como o valor.

```ruby
class Multiply < Micro::Case
  attributes :a, :b

  def call!
    if a.is_a?(Numeric) && b.is_a?(Numeric)
      Success result: { number: a * b }
    else
      Failure(:invalid_data)
    end
  end
end

result = Multiply.call(a: 2, b: '2')

result.failure?            # true
result.data                # { :invalid_data => true }
result.type                # :invalid_data
result.use_case.attributes # {"a"=>2, "b"=>"2"}

# Nota:
# ----
# Essa funcionalidade será muito útil para lidar com resultados de falha de um Flow
# (este tópico será coberto em breve).
```

[⬆️ Voltar para o índice](#índice-)

#### Como utilizar os hooks dos resultados?

Como [mencionando anteriormente](#microcaseresult---o-que-é-o-resultado-de-um-caso-de-uso), o `Micro::Case::Result` tem dois métodos para melhorar o controle do fluxo da aplicação. São eles:
`#on_success`, `on_failure`.

Os exemplos abaixo os demonstram em uso:

```ruby
class Double < Micro::Case
  attribute :number

  def call!
    return Failure :invalid, result: { msg: 'number must be a numeric value' } unless number.is_a?(Numeric)
    return Failure :lte_zero, result: { msg: 'number must be greater than 0' } if number <= 0

    Success result: { number: number * 2 }
  end
end

#================================#
# Imprimindo o output se sucesso #
#================================#

Double
  .call(number: 3)
  .on_success { |result| p result[:number] }
  .on_failure(:invalid) { |result| raise TypeError, result[:msg] }
  .on_failure(:lte_zero) { |result| raise ArgumentError, result[:msg] }

# O output será:
#   6

#===================================#
# Lançando um erro em caso de falha #
#===================================#

Double
  .call(number: -1)
  .on_success { |result| p result[:number] }
  .on_failure { |_result, use_case| puts "#{use_case.class.name} was the use case responsible for the failure" }
  .on_failure(:invalid) { |result| raise TypeError, result[:msg] }
  .on_failure(:lte_zero) { |result| raise ArgumentError, result[:msg] }

# O output será:
#
# 1. Imprimirá a mensagem: Double was the use case responsible for the failure
# 2. Lançará a exception: ArgumentError (the number must be greater than 0)

# Nota:
# ----
# O caso de uso responsável estará sempre acessível como o segundo argumento do hook
```

#### Por que o hook sem um tipo definido expõe o próprio resultado?

Resposta: Para permitir que você defina o controle de fluxo da aplicação usando alguma estrutura condicional como um `if` ou `case when`.

```ruby
class Double < Micro::Case
  attribute :number

  def call!
    return Failure(:invalid) unless number.is_a?(Numeric)
    return Failure :lte_zero, result: attributes(:number) if number <= 0

    Success result: { number: number * 2 }
  end
end

Double
  .call(number: -1)
  .on_failure do |result, use_case|
    case result.type
    when :invalid then raise TypeError, "number must be a numeric value"
    when :lte_zero then raise ArgumentError, "number `#{result[:number]}` must be greater than 0"
    else raise NotImplementedError
    end
  end

# O output será uma exception:
#
# ArgumentError (number `-1` must be greater than 0)
```

> **Nota:** O mesmo que foi feito no exemplo anterior poderá ser feito com o hook `#on_success`!

##### Usando decomposição para acessar os dados e tipo do resultado

A sintaxe para decompor um Array pode ser usada na declaração de variáveis e nos argumentos de métodos/blocos.
Se você não sabia disso, confira a [documentação do Ruby](https://ruby-doc.org/core-2.2.0/doc/syntax/assignment_rdoc.html#label-Array+Decomposition).

```ruby
# O objeto exposto em hook sem um tipo é um Micro::Case::Result e ele pode ser decomposto. Exemplo:

Double
  .call(number: -2)
  .on_failure do |(data, type), use_case|
    case type
    when :invalid then raise TypeError, 'number must be a numeric value'
    when :lte_zero then raise ArgumentError, "number `#{data[:number]}` must be greater than 0"
    else raise NotImplementedError
    end
  end

# O output será a exception:
#
# ArgumentError (the number `-2` must be greater than 0)
```

> **Nota:** O que mesmo pode ser feito com o `#on_success` hook!

[⬆️ Voltar para o índice](#índice-)

#### O que acontece se um hook de resultado for declarado múltiplas vezes?

Resposta: Se o tipo do resultado for identificado o hook será sempre executado.

```ruby
class Double < Micro::Case
  attributes :number

  def call!
    if number.is_a?(Numeric)
      Success :computed, result: { number: number * 2 }
    else
      Failure :invalid, result: { msg: 'number must be a numeric value' }
    end
  end
end

result = Double.call(number: 3)
result.data         # { number: 6 }
result[:number] * 4 # 24

accum = 0

result
  .on_success { |result| accum += result[:number] }
  .on_success { |result| accum += result[:number] }
  .on_success(:computed) { |result| accum += result[:number] }
  .on_success(:computed) { |result| accum += result[:number] }

accum # 24

result[:number] * 4 == accum # true
```

#### Como usar o método `Micro::Case::Result#then`?

Este método permite você criar fluxos dinâmicos. Com ele, você pode adicionar novos casos de uso ou fluxos para continuar a transformação de um resultado. Exemplo:

```ruby
class ForbidNegativeNumber < Micro::Case
  attribute :number

  def call!
    return Success result: attributes if number >= 0

    Failure result: attributes
  end
end

class Add3 < Micro::Case
  attribute :number

  def call!
    Success result: { number: number + 3 }
  end
end

result1 =
  ForbidNegativeNumber
    .call(number: -1)
    .then(Add3)

result1.data    # {'number' => -1}
result1.failure? # true

# ---

result2 =
  ForbidNegativeNumber
    .call(number: 1)
    .then(Add3)

result2.data     # {'number' => 4}
result2.success? # true
```

> **Nota:** este método altera o [`Micro::Case::Result#transitions`](#como-entender-o-que-aconteceu-durante-a-execução-de-um-flow).

[⬆️ Voltar para o índice](#índice-)

##### O que acontece quando um `Micro::Case::Result#then` recebe um bloco?

Ele passará o próprio resultado (uma instância do `Micro::Case::Result`) como argumento do bloco, e retornará o output do bloco ao invés dele mesmo. e.g:

```ruby
class Add < Micro::Case
  attributes :a, :b

  def call!
    if Kind.of?(Numeric, a, b)
      Success result: { sum: a + b }
    else
      Failure(:attributes_arent_numbers)
    end
  end
end

# --

success_result =
  Add
    .call(a: 2, b: 2)
    .then { |result| result.success? ? result[:sum] : 0 }

puts success_result # 4

# --

failure_result =
  Add
    .call(a: 2, b: '2')
    .then { |result| result.success? ? result[:sum] : 0 }

puts failure_result # 0
```

[⬆️ Voltar para o índice](#índice-)

##### Como fazer injeção de dependência usando este recurso?

Passe um `Hash` como segundo argumento do método `Micro::Case::Result#then`.

```ruby
Todo::FindAllForUser
  .call(user: current_user, params: params)
  .then(Paginate)
  .then(Serialize::PaginatedRelationAsJson, serializer: Todo::Serializer)
  .on_success { |result| render_json(200, data: result[:todos]) }
```

[⬆️ Voltar para o índice](#índice-)

### `Micro::Cases::Flow` - Como compor casos de uso?

Chamamos de **fluxo** uma composição de casos de uso. A ideia principal desse recurso é usar/reutilizar casos de uso como etapas de um novo caso de uso. Exemplo:

```ruby
module Steps
  class ConvertTextToNumbers < Micro::Case
    attribute :numbers

    def call!
      if numbers.all? { |value| String(value) =~ /\d+/ }
        Success result: { numbers: numbers.map(&:to_i) }
      else
        Failure result: { message: 'numbers must contain only numeric types' }
      end
    end
  end

  class Add2 < Micro::Case::Strict
    attribute :numbers

    def call!
      Success result: { numbers: numbers.map { |number| number + 2 } }
    end
  end

  class Double < Micro::Case::Strict
    attribute :numbers

    def call!
      Success result: { numbers: numbers.map { |number| number * 2 } }
    end
  end

  class Square < Micro::Case::Strict
    attribute :numbers

    def call!
      Success result: { numbers: numbers.map { |number| number * number } }
    end
  end
end

#-----------------------------------------#
# Criando um flow com Micro::Cases.flow() #
#-----------------------------------------#

Add2ToAllNumbers = Micro::Cases.flow([
  Steps::ConvertTextToNumbers,
  Steps::Add2
])

result = Add2ToAllNumbers.call(numbers: %w[1 1 2 2 3 4])

result.success? # true
result.data    # {:numbers => [3, 3, 4, 4, 5, 6]}

#--------------------------------#
# Criando um flow usando classes #
#--------------------------------#

class DoubleAllNumbers < Micro::Case
  flow Steps::ConvertTextToNumbers,
       Steps::Double
end

DoubleAllNumbers.
  call(numbers: %w[1 1 b 2 3 4]).
  on_failure { |result| puts result[:message] } # "numbers must contain only numeric types"
```

Ao ocorrer uma falha, o caso de uso responsável ficará acessível no resultado. Exemplo:

```ruby
result = DoubleAllNumbers.call(numbers: %w[1 1 b 2 3 4])

result.failure?                                    # true
result.use_case.is_a?(Steps::ConvertTextToNumbers) # true

result.on_failure do |_message, use_case|
  puts "#{use_case.class.name} was the use case responsible for the failure" # Steps::ConvertTextToNumbers was the use case responsible for the failure
end
```

[⬆️ Voltar para o índice](#índice-)

#### É possível compor um fluxo com outros fluxos?

Resposta: Sim, é possível.

```ruby
module Steps
  class ConvertTextToNumbers < Micro::Case
    attribute :numbers

    def call!
      if numbers.all? { |value| String(value) =~ /\d+/ }
        Success result: { numbers: numbers.map(&:to_i) }
      else
        Failure result: { message: 'numbers must contain only numeric types' }
      end
    end
  end

  class Add2 < Micro::Case::Strict
    attribute :numbers

    def call!
      Success result: { numbers: numbers.map { |number| number + 2 } }
    end
  end

  class Double < Micro::Case::Strict
    attribute :numbers

    def call!
      Success result: { numbers: numbers.map { |number| number * 2 } }
    end
  end

  class Square < Micro::Case::Strict
    attribute :numbers

    def call!
      Success result: { numbers: numbers.map { |number| number * number } }
    end
  end
end

DoubleAllNumbers =
  Micro::Cases.flow([Steps::ConvertTextToNumbers, Steps::Double])

SquareAllNumbers =
  Micro::Cases.flow([Steps::ConvertTextToNumbers, Steps::Square])

DoubleAllNumbersAndAdd2 =
  Micro::Cases.flow([DoubleAllNumbers, Steps::Add2])

SquareAllNumbersAndAdd2 =
  Micro::Cases.flow([SquareAllNumbers, Steps::Add2])

SquareAllNumbersAndDouble =
  Micro::Cases.flow([SquareAllNumbersAndAdd2, DoubleAllNumbers])

DoubleAllNumbersAndSquareAndAdd2 =
  Micro::Cases.flow([DoubleAllNumbers, SquareAllNumbersAndAdd2])

SquareAllNumbersAndDouble
  .call(numbers: %w[1 1 2 2 3 4])
  .on_success { |result| p result[:numbers] } # [6, 6, 12, 12, 22, 36]

DoubleAllNumbersAndSquareAndAdd2
  .call(numbers: %w[1 1 2 2 3 4])
  .on_success { |result| p result[:numbers] } # [6, 6, 18, 18, 38, 66]
```

> **Nota:** Você pode mesclar qualquer [approach](#é-possível-compor-um-fluxo-com-outros-fluxos) para criar flows - [exemplos](https://github.com/serradura/u-case/blob/714c6b658fc6aa02617e6833ddee09eddc760f2a/test/micro/cases/flow/blend_test.rb#L5-L35).

[⬆️ Voltar para o índice](#índice-)

#### É possível que um fluxo acumule sua entrada e mescle cada resultado de sucesso para usar como argumento dos próximos casos de uso?

Resposta: Sim, é possível! Veja o exemplo abaixo para entender como funciona o acúmulo de dados dentro da execução de um fluxo.

```ruby
module Users
  class FindByEmail < Micro::Case
    attribute :email

    def call!
      user = User.find_by(email: email)

      return Success result: { user: user } if user

      Failure(:user_not_found)
    end
  end
end

module Users
  class ValidatePassword < Micro::Case::Strict
    attributes :user, :password

    def call!
      return Failure(:user_must_be_persisted) if user.new_record?
      return Failure(:wrong_password) if user.wrong_password?(password)

      return Success result: attributes(:user)
    end
  end
end

module Users
  Authenticate = Micro::Cases.flow([
    FindByEmail,
    ValidatePassword
  ])
end

Users::Authenticate
  .call(email: 'somebody@test.com', password: 'password')
  .on_success { |result| sign_in(result[:user]) }
  .on_failure(:wrong_password) { render status: 401 }
  .on_failure(:user_not_found) { render status: 404 }
```

Primeiro, vamos ver os atributos usados por cada caso de uso:

```ruby
class Users::FindByEmail < Micro::Case
  attribute :email
end

class Users::ValidatePassword < Micro::Case
  attributes :user, :password
end
```

Como você pode ver, `Users::ValidatePassword` espera um usuário como sua entrada. Então, como ele recebe o usuário?
R: Ele recebe o usuário do resultado de sucesso `Users::FindByEmail`!

E este é o poder da composição de casos de uso porque o output de uma etapa irá compor a entrada do próximo caso de uso no fluxo!

> input **>>** processamento **>>** output

> **Nota:** Verifique esses exemplos de teste [Micro::Cases::Flow](https://github.com/serradura/u-case/blob/c96a3650469da40dc9f83ff678204055b7015d01/test/micro/cases/flow/result_transitions_test.rb) e [Micro::Cases::Safe::Flow](https://github.com/serradura/u-case/blob/c96a3650469da40dc9f83ff678204055b7015d01/test/micro/cases/safe/flow/result_transitions_test.rb) para ver diferentes casos de uso tendo acesso aos dados de um fluxo.

[⬆️ Voltar para o índice](#índice-)

#### Como entender o que aconteceu durante a execução de um flow?

Use `Micro::Case::Result#transitions`!

Vamos usar os [exemplos da seção anterior](#is-it-possible-a-flow-accumulates-its-input-and-merges-each-success-result-to-use-as-the-argument-of-the-next-use-cases) para ilustrar como utilizar essa feature.

```ruby
user_authenticated =
  Users::Authenticate.call(email: 'rodrigo@test.com', password: user_password)

user_authenticated.transitions
[
  {
    :use_case => {
      :class      => Users::FindByEmail,
      :attributes => { :email => "rodrigo@test.com" }
    },
    :success => {
      :type  => :ok,
      :result => {
        :user => #<User:0x00007fb57b1c5f88 @email="rodrigo@test.com" ...>
      }
    },
    :accessible_attributes => [ :email, :password ]
  },
  {
    :use_case => {
      :class      => Users::ValidatePassword,
      :attributes => {
        :user     => #<User:0x00007fb57b1c5f88 @email="rodrigo@test.com" ...>
        :password => "123456"
      }
    },
    :success => {
      :type  => :ok,
      :result => {
        :user => #<User:0x00007fb57b1c5f88 @email="rodrigo@test.com" ...>
      }
    },
    :accessible_attributes => [ :email, :password, :user ]
  }
]
```

O exemplo acima mostra a saída gerada pelas `Micro::Case::Result#transitions`.
Com ele é possível analisar a ordem de execução dos casos de uso e quais foram os `inputs` fornecidos (`[:attributes]`) e `outputs` (`[:success][:result]`) em toda a execução.

E observe a propriedade `accessible_attributes`, ela mostra quais atributos são acessíveis nessa etapa do fluxo. Por exemplo, na última etapa, você pode ver que os atributos `accessible_attributes` aumentaram devido ao [acúmulo de fluxo de dados](#é-possível-que-um-fluxo-acumule-sua-entrada-e-mescle-cada-resultado-de-sucesso-para-usar-como-argumento-dos-próximos-casos-de-uso).

> **Nota:** O [`Micro::Case::Result#then`](#how-to-use-the-microcaseresultthen-method) incrementa o `Micro::Case::Result#transitions`.

##### `Micro::Case::Result#transitions` schema
```ruby
[
  {
    use_case: {
      class:      <Micro::Case>,# Caso de uso que será executado
      attributes: <Hash>        # (Input) Os atributos do caso de uso
    },
    [success:, failure:] => {   # (Output)
      type:  <Symbol>,          # Tipo do resultado. Padrões:
                                # Success = :ok, Failure = :error or :exception
      result: <Hash>            # Os dados retornados pelo resultado do use case
    },
    accessible_attributes: <Array>, # Propriedades que podem ser acessadas pelos atributos do caso de uso,
                                    # começando com Hash usado para invocá-lo e que são incrementados
                                    # com os valores de resultado de cada caso de uso do fluxo.
  }
]

```

##### É possível desabilitar o `Micro::Case::Result#transitions`?

Resposta: Sim! Você pode usar o `Micro::Case.config` para fazer isso. [Link para](#microcaseconfig) essa seção.

#### É possível declarar um fluxo que inclui o próprio caso de uso?

Resposta: Sim! Você pode usar a macro `self` ou `self.call!`. Exemplo:

```ruby
class ConvertTextToNumber < Micro::Case
  attribute :text

  def call!
    Success result: { number: text.to_i }
  end
end

class ConvertNumberToText < Micro::Case
  attribute :number

  def call!
    Success result: { text: number.to_s }
  end
end

class Double < Micro::Case
  flow ConvertTextToNumber,
       self.call!,
       ConvertNumberToText

  attribute :number

  def call!
    Success result: { number: number * 2 }
  end
end

result = Double.call(text: '4')

result.success? # true
result[:number] # "8"
```

> **Note:** Essa funcionalidade pode ser usada com Micro::Case::Safe. Verifique esse teste para ver um example: https://github.com/serradura/u-case/blob/714c6b658fc6aa02617e6833ddee09eddc760f2a/test/micro/case/safe/with_inner_flow_test.rb

[⬆️ Voltar para o índice](#índice-)

### `Micro::Case::Strict` - O que é um caso de uso estrito?

Resposta: é um tipo de caso de uso que exigirá todas as palavras-chave (atributos) em sua inicialização.

```ruby
class Double < Micro::Case::Strict
  attribute :numbers

  def call!
    Success result: { numbers: numbers.map { |number| number * 2 } }
  end
end

Double.call({})

# O output será:
# ArgumentError (missing keyword: :numbers)
```

[⬆️ Voltar para o índice](#índice-)

### `Micro::Case::Safe` - Existe algum recurso para lidar automaticamente com exceções dentro de um caso de uso ou fluxo?

Sim, assim como `Micro::Case::Strict`, o `Micro::Case::Safe` é outro tipo de caso de uso. Ele tem a capacidade de interceptar automaticamente qualquer exceção como um resultado de falha. Exemplo:

```ruby
require 'logger'

AppLogger = Logger.new(STDOUT)

class Divide < Micro::Case::Safe
  attributes :a, :b

  def call!
    if a.is_a?(Integer) && b.is_a?(Integer)
      Success result: { number: a / b}
    else
      Failure(:not_an_integer)
    end
  end
end

result = Divide.call(a: 2, b: 0)
result.type == :exception                   # true
result.data                                 # { exception: #<ZeroDivisionError...> }
result[:exception].is_a?(ZeroDivisionError) # true

result.on_failure(:exception) do |result|
  AppLogger.error(result[:exception].message) # E, [2019-08-21T00:05:44.195506 #9532] ERROR -- : divided by 0
end
```

#### `Micro::Case::Result#on_exception`

Se você precisar lidar com um erro específico, recomendo o uso de uma instrução case. Exemplo:

```ruby
result.on_failure(:exception) do |data, use_case|
  case exception = data[:exception]
  when ZeroDivisionError then AppLogger.error(exception.message)
  else AppLogger.debug("#{use_case.class.name} was the use case responsible for the exception")
  end
end
```

> **Note:** É possível resgatar uma exceção mesmo quando é um caso de uso seguro. Exemplos: https://github.com/serradura/u-case/blob/714c6b658fc6aa02617e6833ddee09eddc760f2a/test/micro/case/safe_test.rb#L90-L118


[⬆️ Voltar para o índice](#índice-)

#### `Micro::Cases::Safe::Flow`

Como casos de uso seguros, os fluxos seguros podem interceptar uma exceção em qualquer uma de suas etapas. Estas são as maneiras de definir um:

```ruby
module Users
  Create = Micro::Cases.safe_flow([
    ProcessParams,
    ValidateParams,
    Persist,
    SendToCRM
  ])
end
```

Definindo dentro das classes:

```ruby
module Users
  class Create < Micro::Case::Safe
    flow ProcessParams,
         ValidateParams,
         Persist,
         SendToCRM
  end
end
```

[⬆️ Voltar para o índice](#índice-)

#### `Micro::Case::Result#on_exception`

Na programação funcional os erros/exceções são tratados como dados comuns, a ideia é transformar a saída mesmo quando ocorre um comportamento inesperado. Para muitos, [as exceções são muito semelhantes à instrução GOTO](https://softwareengineering.stackexchange.com/questions/189222/are-exceptions-as-control-flow-considered-a-serious-antipattern-if-so-why), pulando o fluxo do programa para caminhos que podem ser difíceis de descobrir como as coisas funcionam em um sistema.

Para resolver isso, o `Micro::Case::Result` tem um hook especial `#on_exception` para ajudá-lo a lidar com o fluxo de controle no caso de exceções.

> **Note**: essa funcionalidade funcionará melhor se for usada com um flow ou caso de uso `Micro::Case::Safe`.

**Como ele funciona?**

```ruby
class Divide < Micro::Case::Safe
  attributes :a, :b

  def call!
    Success result: { division: a / b }
  end
end

Divide
  .call(a: 2, b: 0)
  .on_success { |result| puts result[:division] }
  .on_exception(TypeError) { puts 'Please, use only numeric attributes.' }
  .on_exception(ZeroDivisionError) { |_error| puts "Can't divide a number by 0." }
  .on_exception { |_error, _use_case| puts 'Oh no, something went wrong!' }

# Output:
# -------
# Can't divide a number by 0
# Oh no, something went wrong!

Divide.
  .call(a: 2, b: '2').
  .on_success { |result| puts result[:division] }
  .on_exception(TypeError) { puts 'Please, use only numeric attributes.' }
  .on_exception(ZeroDivisionError) { |_error| puts "Can't divide a number by 0." }
  .on_exception { |_error, _use_case| puts 'Oh no, something went wrong!' }

# Output:
# -------
# Please, use only numeric attributes.
# Oh no, something went wrong!
```

Como você pode ver, este hook tem o mesmo comportamento de `result.on_failure(:exception)`, mas, a ideia aqui é ter uma melhor comunicação no código, fazendo uma referência explícita quando alguma falha acontecer por causa de uma exceção.

[⬆️ Voltar para o índice](#índice-)

### `u-case/with_activemodel_validation` - Como validar os atributos do caso de uso?

**Requisitos:**

Para fazer isso a sua aplicação deverá ter o [activemodel >= 3.2, < 6.1.0](https://rubygems.org/gems/activemodel) como dependência.

Por padrão, se a sua aplicação tiver o ActiveModel como uma dependência, qualquer tipo de caso de uso pode fazer uso dele para validar seus atributos.

```ruby
class Multiply < Micro::Case
  attributes :a, :b

  validates :a, :b, presence: true, numericality: true

  def call!
    return Failure :invalid_attributes, result: { errors: self.errors } if invalid?

    Success result: { number: a * b }
  end
end
```

Mas se você deseja uma maneira automática de falhar seus casos de uso em erros de validação, você poderá fazer:

1. **require 'u-case/with_activemodel_validation'** no Gemfile

  ```ruby
  gem 'u-case', require: 'u-case/with_activemodel_validation'
  ```

2. Usar o `Micro::Case.config` para habilitar ele. [Link para](#microcaseconfig) essa seção.

Usando essa abordagem, você pode reescrever o exemplo anterior com menos código. Exemplo:

```ruby
require 'u-case/with_activemodel_validation'

class Multiply < Micro::Case
  attributes :a, :b

  validates :a, :b, presence: true, numericality: true

  def call!
    Success result: { number: a * b }
  end
end
```

> **Nota:** Após habilitar o modo de validação, as classes `Micro::Case::Strict` e `Micro::Case::Safe` irão herdar este novo comportamento.

#### Se eu habilitei a validação automática, é possível desabilitá-la apenas em casos de uso específicos?

Resposta: Sim, é possível. Para fazer isso, você só precisará usar a macro `disable_auto_validation`. Exemplo:

```ruby
require 'u-case/with_activemodel_validation'

class Multiply < Micro::Case
  disable_auto_validation

  attribute :a
  attribute :b
  validates :a, :b, presence: true, numericality: true

  def call!
    Success result: { number: a * b }
  end
end

Multiply.call(a: 2, b: 'a')

# O output será:
# TypeError (String can't be coerced into Integer)
```

[⬆️ Voltar para o índice](#índice-)

#### `Kind::Validator`

A [gem kind](https://github.com/serradura/kind) possui um módulo para habilitar a validação do tipo de dados através do [`ActiveModel validations`](https://guides.rubyonrails.org/active_model_basics.html#validations). Então, quando você fizer o require do `'u-case/with_activemodel_validation'`, este módulo também irá fazer o require do [`Kind::Validator`](https://github.com/serradura/kind#kindvalidator-activemodelvalidations).

O exemplo abaixo mostra como validar os tipos de atributos.

```ruby
class Todo::List::AddItem < Micro::Case
  attributes :user, :params

  validates :user, kind: User
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

[⬆️ Voltar para o índice](#índice-)

## `Micro::Case.config`

A ideia deste recurso é permitir a configuração de algumas funcionalidades/módulos do `u-case`.
Eu recomendo que você use apenas uma vez em sua base de código. Exemplo: Em um inicializador do Rails.

Você pode ver abaixo todas as configurações disponíveis com seus valores padrão:

```ruby
Micro::Case.config do |config|
  # Use ActiveModel para auto-validar os atributos dos seus casos de uso.
  config.enable_activemodel_validation = false

  # Use para habilitar/desabilitar o `Micro::Case::Results#transitions`.
  config.enable_transitions = true
end
```

[⬆️ Voltar para o índice](#índice-)

## Benchmarks

### `Micro::Case`

#### Success results

| Gem / Abstração        | Iterações por segundo |        Comparação |
| -----------------      | --------------------: | ----------------: |
| Dry::Monads            |              281515.4 | _**O mais rápido**_ |
| **Micro::Case**        |              151711.3 |     1.86x mais lento  |
| Interactor             |               53016.2 |     5.31x mais lento  |
| Trailblazer::Operation |               38314.2 |     7.35x mais lento  |
| Dry::Transaction       |               10440.7 |    26.96x mais lento  |

<details>
  <summary>Show the full <a href="https://github.com/evanphx/benchmark-ips">benchmark/ips</a> results.</summary>

```ruby
# Warming up --------------------------------------
#           Interactor     5.151k i/100ms
# Trailblazer::Operation   3.805k i/100ms
#          Dry::Monads    28.153k i/100ms
#     Dry::Transaction     1.063k i/100ms
#          Micro::Case    15.159k i/100ms
#    Micro::Case::Safe    15.172k i/100ms
#  Micro::Case::Strict    12.557k i/100ms

# Calculating -------------------------------------
#           Interactor     53.016k (± 1.8%) i/s -    267.852k in   5.053967s
# Trailblazer::Operation   38.314k (± 1.7%) i/s -    194.055k in   5.066374s
#          Dry::Monads    281.515k (± 2.4%) i/s -      1.408M in   5.003266s
#     Dry::Transaction     10.441k (± 2.1%) i/s -     53.150k in   5.092957s
#          Micro::Case    151.711k (± 1.7%) i/s -    773.109k in   5.097555s
#    Micro::Case::Safe    145.801k (± 6.7%) i/s -    728.256k in   5.022666s
#  Micro::Case::Strict    115.636k (± 8.4%) i/s -    577.622k in   5.042079s

# Comparison:
#          Dry::Monads:   281515.4 i/s
#          Micro::Case:   151711.3 i/s - 1.86x  (± 0.00) slower
#    Micro::Case::Safe:   145800.8 i/s - 1.93x  (± 0.00) slower
#  Micro::Case::Strict:   115635.8 i/s - 2.43x  (± 0.00) slower
#           Interactor:    53016.2 i/s - 5.31x  (± 0.00) slower
# Trailblazer::Operation:  38314.2 i/s - 7.35x  (± 0.00) slower
#     Dry::Transaction:    10440.7 i/s - 26.96x  (± 0.00) slower
```
</details>

https://github.com/serradura/u-case/blob/main/benchmarks/perfomance/use_case/success_results.

#### Failure results

| Gem / Abstração        | Iterações por segundo |        Comparação |
| -----------------      | --------------------: | ----------------: |
| **Micro::Case**        |              140794.0 | _**O mais rápido**_ |
| Dry::Monads            |              133865.5 |        0x mais devagar  |
| Trailblazer::Operation |               39829.9 |     3.53x mais devagar  |
| Interactor             |               23856.0 |     5.90x mais devagar  |
| Dry::Transaction       |                7975.0 |    17.65x mais devagar  |

<details>
  <summary>Mostrar o resultado completo do <a href="https://github.com/evanphx/benchmark-ips">benchmark/ips</a>.</summary>

```ruby
# Warming up --------------------------------------
#           Interactor     2.351k i/100ms
# Trailblazer::Operation   3.941k i/100ms
#          Dry::Monads    13.567k i/100ms
#     Dry::Transaction   927.000  i/100ms
#          Micro::Case    14.959k i/100ms
#    Micro::Case::Safe    14.904k i/100ms
#  Micro::Case::Strict    12.007k i/100ms

# Calculating -------------------------------------
#           Interactor     23.856k (± 1.7%) i/s -    119.901k in   5.027585s
# Trailblazer::Operation   39.830k (± 1.2%) i/s -    200.991k in   5.047032s
#          Dry::Monads    133.866k (± 2.5%) i/s -    678.350k in   5.070899s
#     Dry::Transaction      7.975k (± 8.6%) i/s -     39.861k in   5.036260s
#          Micro::Case    130.534k (±24.4%) i/s -    583.401k in   5.040907s
#    Micro::Case::Safe    140.794k (± 8.1%) i/s -    700.488k in   5.020935s
#  Micro::Case::Strict    102.641k (±21.3%) i/s -    480.280k in   5.020354s

# Comparison:
#    Micro::Case::Safe:   140794.0 i/s
#          Dry::Monads:   133865.5 i/s - same-ish: difference falls within error
#          Micro::Case:   130534.0 i/s - same-ish: difference falls within error
#  Micro::Case::Strict:   102640.7 i/s - 1.37x  (± 0.00) slower
# Trailblazer::Operation:  39829.9 i/s - 3.53x  (± 0.00) slower
#           Interactor:    23856.0 i/s - 5.90x  (± 0.00) slower
#     Dry::Transaction:     7975.0 i/s - 17.65x  (± 0.00) slower
```
</details>

https://github.com/serradura/u-case/blob/main/benchmarks/perfomance/use_case/failure_results.

---

### `Micro::Cases::Flow`

| Gem / Abstração      | [Resultados de sucesso](https://github.com/serradura/u-case/blob/main/benchmarks/perfomance/flow/success_results.rb) | [Resultados de falha](https://github.com/serradura/u-case/blob/main/benchmarks/perfomance/flow/failure_results.rb) |
| ------------------------------------------- | ----------------: | ----------------: |
| Micro::Case::Result `pipe` method           |      172734.4 i/s |      153745.6 i/s |
| Micro::Case::Result `then` method           | 1.24x mais devagar | 1.21x mais devagar |
| Micro::Cases.flow                           | 1.30x mais devagar | 1.30x mais devagar |
| Micro::Case class with an inner flow        | 2.05x mais devagar | 1.98x mais devagar |
| Micro::Case class including itself as a step| 2.14x mais devagar | 2.09x mais devagar |
| Interactor::Organizer                       | 7.69x mais devagar | 7.03x mais devagar |

\* As gems `Dry::Monads`, `Dry::Transaction`, `Trailblazer::Operation` estão fora desta análise por não terem esse tipo de funcionalidade.

<details>
  <summary><strong>Resultados de sucesso</strong> - Mostrar o resultado completo do benchmark/ips.</summary>

```ruby
# Warming up --------------------------------------
# Interactor::Organizer            2.163k i/100ms
# Micro::Cases.flow([])           13.158k i/100ms
# Micro::Case flow in a class      8.400k i/100ms
# Micro::Case including the class  8.008k i/100ms
# Micro::Case::Result#|           17.151k i/100ms
# Micro::Case::Result#then        14.121k i/100ms

# Calculating -------------------------------------
# Interactor::Organizer            22.467k (± 1.8%) i/s -    112.476k in   5.007787s
# Micro::Cases.flow([])           133.183k (± 1.5%) i/s -    671.058k in   5.039815s
# Micro::Case flow in a class      84.083k (± 1.8%) i/s -    428.400k in   5.096623s
# Micro::Case including the class  80.574k (± 1.6%) i/s -    408.408k in   5.070029s
# Micro::Case::Result#|           172.734k (± 1.1%) i/s -    874.701k in   5.064429s
# Micro::Case::Result#then        139.799k (± 1.7%) i/s -    706.050k in   5.052035s

# Comparison:
# Micro::Case::Result#|:          172734.4 i/s
# Micro::Case::Result#then:       139799.0 i/s - 1.24x  (± 0.00) slower
# Micro::Cases.flow([]):          133182.9 i/s - 1.30x  (± 0.00) slower
# Micro::Case flow in a class:     84082.6 i/s - 2.05x  (± 0.00) slower
# Micro::Case including the class: 80574.3 i/s - 2.14x  (± 0.00) slower
# Interactor::Organizer:           22467.4 i/s - 7.69x  (± 0.00) slower
```
</details>

<details>
  <summary><strong>Resultados de falha</strong> - Mostrar o resultado completo do benchmark/ips.</summary>

```ruby
# Warming up --------------------------------------
# Interactor::Organizer            2.167k i/100ms
# Micro::Cases.flow([])           11.797k i/100ms
# Micro::Case flow in a class      7.783k i/100ms
# Micro::Case including the class  7.097k i/100ms
# Micro::Case::Result#|           14.398k i/100ms
# Micro::Case::Result#then        12.719k i/100ms

# Calculating -------------------------------------
# Interactor::Organizer            21.863k (± 2.5%) i/s -    110.517k in   5.058420s
# Micro::Cases.flow([])           118.124k (± 1.8%) i/s -    601.647k in   5.095102s
# Micro::Case flow in a class      77.801k (± 1.5%) i/s -    389.150k in   5.003002s
# Micro::Case including the class  73.533k (± 2.1%) i/s -    369.044k in   5.021076s
# Micro::Case::Result#|           153.746k (± 1.5%) i/s -    777.492k in   5.058177s
# Micro::Case::Result#then        126.897k (± 1.7%) i/s -    635.950k in   5.013059s

# Comparison:
# Micro::Case::Result#|:          153745.6 i/s
# Micro::Case::Result#then:       126896.6 i/s - 1.21x  (± 0.00) slower
# Micro::Cases.flow([]):          118123.9 i/s - 1.30x  (± 0.00) slower
# Micro::Case flow in a class:     77800.7 i/s - 1.98x  (± 0.00) slower
# Micro::Case including the class: 73532.9 i/s - 2.09x  (± 0.00) slower
# Interactor::Organizer:           21862.9 i/s - 7.03x  (± 0.00) slower
```
</details>

https://github.com/serradura/u-case/blob/main/benchmarks/perfomance/flow/

[⬆️ Voltar para o índice](#índice-)

### Execuntando os benchmarks

#### Performance (Benchmarks IPS)

Clone este repositório e acesse a sua pasta, então execute os comandos abaixo:

**Casos de uso**

```sh
ruby benchmarks/perfomance/use_case/failure_results.rb
ruby benchmarks/perfomance/use_case/success_results.rb
```

**Flows**

```sh
ruby benchmarks/perfomance/flow/failure_results.rb
ruby benchmarks/perfomance/flow/success_results.rb
```

#### Memory profiling

**Casos de uso**

```sh
./benchmarks/memory/use_case/success/with_transitions/analyze.sh
./benchmarks/memory/use_case/success/without_transitions/analyze.sh
```

**Flows**

```sh
./benchmarks/memory/flow/success/with_transitions/analyze.sh
./benchmarks/memory/flow/success/without_transitions/analyze.sh
```

[⬆️ Voltar para o índice](#índice-)

### Comparações

Confira as implementações do mesmo caso de uso com diferentes gems/abstrações.

* [interactor](https://github.com/serradura/u-case/blob/main/comparisons/interactor.rb)
* [u-case](https://github.com/serradura/u-case/blob/main/comparisons/u-case.rb)

[⬆️ Voltar para o índice](#índice-)

## Exemplos

### 1️⃣ Criação de usuários

> Um exemplo de fluxo que define etapas para higienizar, validar e persistir seus dados de entrada. Ele tem todas as abordagens possíveis para representar casos de uso com a gem `u-case`.
>
> Link: https://github.com/serradura/u-case/blob/main/examples/users_creation

### 2️⃣ Rails App (API)

> Este projeto mostra diferentes tipos de arquitetura (uma por commit), e na última, como usar a gem `Micro::Case` para lidar com a lógica de negócios da aplicação.
>
> Link: https://github.com/serradura/from-fat-controllers-to-use-cases

### 3️⃣ CLI calculator

> Rake tasks para demonstrar como lidar com os dados do usuário e como usar diferentes tipos de falha para controlar o fluxo do programa.
>
> Link: https://github.com/serradura/u-case/tree/main/examples/calculator

### 4️⃣ Interceptando exceções dentro dos casos de uso

> Link: https://github.com/serradura/u-case/blob/main/examples/rescuing_exceptions.rb

[⬆️ Voltar para o índice](#índice-)

## Desenvolvimento

Após fazer o checking out do repo, execute `bin/setup` para instalar dependências. Então, execute `./test.sh` para executar os testes. Você pode executar `bin/console` para ter um prompt interativo que permitirá você experimenta-lá.

Para instalar esta gem em sua máquina local, execute `bundle exec rake install`. Para lançar uma nova versão, atualize o número da versão em `version.rb` e execute` bundle exec rake release`, que criará uma tag git para a versão, enviará git commits e tags e enviará o arquivo `.gem`para [rubygems.org](https://rubygems.org).

## Contribuindo

Reportar bugs e solicitar pull requests são bem-vindos no GitHub em https://github.com/serradura/u-case. Este projeto pretende ser um espaço seguro e acolhedor para colaboração, e espera-se que os colaboradores sigam o código de conduta do [Covenant do Contribuidor](http://contributor-covenant.org).

## Licença

A gem está disponível como código aberto nos termos da [licença MIT](https://opensource.org/licenses/MIT).

## Código de conduta

Espera-se que todos que interagem com o codebase do projeto `Micro::Case`, issue trackers, chat rooms and mailing lists sigam o [código de conduta](https://github.com/serradura/u-case/blob/main/CODE_OF_CONDUCT.md).
