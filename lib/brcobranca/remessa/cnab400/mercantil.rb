# -*- encoding: utf-8 -*-
module Brcobranca
  module Remessa
    module Cnab400
      # http://mercantildobrasil.com.br/Anexos/PDFs/Empresas/Cobranca/CobrancaCNAB400.pdf
      class Mercantil < Brcobranca::Remessa::Cnab400::Base
        # documento do cedente
        attr_accessor :documento_cedente
        
        # numero do contrato
        attr_accessor :numero_contrato
        
        validates_presence_of :agencia, :conta_corrente, :documento_cedente, message: 'não pode estar em branco.'
        validates_presence_of :sequencial_remessa, :digito_conta, :numero_contrato, message: 'não pode estar em branco.'
        validates_length_of :agencia, maximum: 5, message: 'deve ter 5 dígitos.'
        validates_length_of :conta_corrente, :sequencial_remessa, maximum: 7, message: 'deve ter 7 dígitos.'
        validates_length_of :digito_conta, maximum: 1, message: 'deve ter 1 dígito.'
        validates_length_of :documento_cedente, minimum: 11, maximum: 14, message: 'deve ter entre 11 e 14 dígitos.'
        validates_length_of :numero_contrato, maximum: 9, message: 'deve ter no máximo 9 dígitos.'

        def agencia=(valor)
          @agencia = valor.to_s.rjust(4, '0') if valor
        end

        def conta_corrente=(valor)
          @conta_corrente = valor.to_s.rjust(7, '0') if valor
        end

        def sequencial_remessa=(valor)
          @sequencial_remessa = valor.to_s.rjust(5, '0') if valor
        end
        
        def documento_cedente=(valor)
          @documento_cedente = valor.to_s.rjust(14, '0') if valor
        end

        def info_conta
          "#{agencia}#{documento_cedente}#{''.rjust(1,' ')}"
        end

        def cod_banco
          '389'
        end

        def nome_banco
          'BANCANTIL'.ljust(15, ' ')
        end

        def complemento
          "#{''.rjust(281, ' ')}01600#{''.rjust(3, ' ')}#{sequencial_remessa}"
        end
        
        def digito_nosso_numero(nosso_numero)
          "#{agencia}#{nosso_numero}".modulo11_mercantil { |valor| [0,1].include?(valor) ? 0 : (11 - valor) }
        end

        # Header do arquivo remessa
        #
        # @return [String]
        #
        def monta_header
          "01REMESSA01COBRANCA       #{info_conta}#{empresa_mae.format_size(30)}#{cod_banco}#{nome_banco}#{data_geracao}#{complemento}000001"
        end

        def monta_detalhe(pagamento, sequencial)
          fail Brcobranca::RemessaInvalida.new(pagamento) if pagamento.invalid?

          detalhe = '1'                                               # identificacao do registro                   9[01]       001 a 001
          detalhe << '00'                                             # identificacao da multa
          detalhe << '0'                                              # código da multa
          detalhe << '0'.rjust(11, 0)                                 # percentual da multa
          detalhe << '0'.rjust(6, 0)                                  # data da multa
          detalhe << ''.rjust(5, ' ')                                 # branco
          detalhe << numero_contrato.rjust(9, '0')                    # numero contrato
          detalhe << pagamento.nosso_numero.to_s.rjust(25, '0')       # identificacao do titulo
          detalhe << agencia                                          # agencia
          detalhe << pagamento.nosso_numero.to_s.rjust(10, '0')       # nosso numero
          detalhe << digito_nosso_numero(pagamento.nosso_numero).to_s # digito nosso numero
          detalhe << ''.rjust(5, ' ')                                 # brancos
          detalhe << documento_cedente.to_s.rjust(15, '0')            # cpf/cnpj
          detalhe << ''.rjust(10, '0')                                # qtde moeda
          detalhe << '1'                                              # codigo operacao
          detalhe << '01'                                             # codigo movimento
          detalhe << ''.rjust(10, '0')                                # seu numero
          detalhe << pagamento.data_vencimento.strftime('%d%m%y')     # vencimento
          detalhe << pagamento.formata_valor                          # valor titulo
          detalhe << cod_banco                                        # banco cobrador
          detalhe << ''.rjust(5, '0')                                 # agencia cobranca
          detalhe << '01'                                             # codigo especie
          detalhe << 'N'                                              # aceite
          detalhe << pagamento.data_emissao.strftime('%d%m%y')        # data emissao
          detalhe << ''.rjust(2, ' ')                                 # instrução 1
          detalhe << ''.rjust(2, ' ')                                 # instrução 2
          detalhe << pagamento.formata_valor_mora                     # juros mora
          detalhe << pagamento.formata_data_desconto                  # desconto até
          detalhe << pagamento.formata_valor_desconto                 # valor desconto
          detalhe << pagamento.formata_valor_iof                      # valor iof
          detalhe << pagamento.formata_valor_abatimento               # valor abatimento
          detalhe << pagamento.identificacao_sacado                   # codigo inscricao pagador
          detalhe << pagamento.documento_sacado.to_s.rjust(14, '0')   # numero cpf/cnpj
          detalhe << pagamento.nome_sacado.format_size(40)            # nome pagador
          detalhe << pagamento.endereco_sacado.format_size(40)        # endereco pagador
          detalhe << pagamento.bairro_sacado.format_size(12)          # bairro pagador
          detalhe << pagamento.cep_sacado[0..4]                       # cep prefixo pagador
          detalhe << pagamento.cep_sacado[5..7]                       # cep sufixo pagador
          detalhe << pagamento.cidade_sacado.format_size(15)          # cidade pagador
          detalhe << pagamento.uf_sacado                              # estado pagador
          detalhe << pagamento.nome_avalista.format_size(40)          # nome pagador/avalista
          detalhe << ''.rjust(12, ' ')                                # brancos
          detalhe << '1'                                              # codigo moeda
          detalhe << sequencial.to_s.rjust(6, '0')                    # sequencia
          detalhe
        end

        # Trailer do arquivo remessa
        #
        # @param sequencial
        #   num. sequencial do registro no arquivo
        #
        # @return [String]
        #
        def monta_trailer(sequencial)
          "9#{''.to_s.rjust(393, ' ')}#{sequencial.to_s.rjust(6, '0')}"
        end
        
      end
    end
  end
end
