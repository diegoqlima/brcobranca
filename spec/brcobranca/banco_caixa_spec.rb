# -*- encoding: utf-8 -*-
require File.dirname(__FILE__) + '/../spec_helper.rb'

describe Brcobranca::Boleto::Caixa do #:nodoc:[all]

  before do
    @valid_attributes = {
      :especie_documento => 'DM',
      :moeda => '9',
      :data_documento => Date.today,
      :dias_vencimento => 1,
      :aceite => 'S',
      :quantidade => 1,
      :valor => 10.00,
      :cedente => 'PREFEITURA MUNICIPAL DE VILHENA',
      :documento_cedente => '04092706000181',
      :sacado => 'João Paulo Barbosa',
      :sacado_documento => '77777777777',
      :agencia => '1825',
      :conta_corrente => '0000528',
      :convenio => '245274',
      :numero_documento => '000000000000001'
    }
  end

  it 'Criar nova instância com atributos padrões' do
    boleto_novo = Brcobranca::Boleto::Caixa.new
    expect(boleto_novo.banco).to eql('104')
    expect(boleto_novo.banco_dv).to eql('0')
    expect(boleto_novo.especie_documento).to eql('DM')
    expect(boleto_novo.especie).to eql('R$')
    expect(boleto_novo.moeda).to eql('9')
    expect(boleto_novo.data_documento).to eql(Date.today)
    expect(boleto_novo.dias_vencimento).to eql(1)
    expect(boleto_novo.data_vencimento).to eql(Date.today + 1)
    expect(boleto_novo.aceite).to eql('S')
    expect(boleto_novo.quantidade).to eql(1)
    expect(boleto_novo.valor).to eql(0.0)
    expect(boleto_novo.valor_documento).to eql(0.0)
    expect(boleto_novo.local_pagamento).to eql('PREFERENCIALMENTE NAS CASAS LOTÉRICAS ATÉ O VALOR LIMITE')
    expect(boleto_novo.codigo_servico).to be_falsey
    carteira = "#{Brcobranca::Boleto::Caixa::MODALIDADE_COBRANCA[:sem_registro]}" <<
               "#{Brcobranca::Boleto::Caixa::EMISSAO_BOLETO[:cedente]}"
    expect(boleto_novo.carteira).to eql(carteira)
  end

  it "Criar nova instancia com atributos válidos" do
    boleto_novo = Brcobranca::Boleto::Caixa.new @valid_attributes
    @valid_attributes.keys.each do |key|
      expect(boleto_novo.send(key)).to eql(@valid_attributes[key])
    end
    expect(boleto_novo).to be_valid
  end

  it 'Gerar o dígito verificador do convênio' do
    boleto_novo = Brcobranca::Boleto::Caixa.new @valid_attributes
    expect(boleto_novo.convenio_dv).not_to be_nil
    expect(boleto_novo.convenio_dv).to eq('0')
  end

  it "Gerar o código de barras" do
    boleto_novo = Brcobranca::Boleto::Caixa.new @valid_attributes
    expect { boleto_novo.codigo_barras }.not_to raise_error
    expect(boleto_novo.codigo_barras_segunda_parte).not_to be_blank
    expect(boleto_novo.codigo_barras_segunda_parte).to eql('2452740000200040000000010')
  end

  it "Não permitir gerar boleto com atributos inválidos" do
    boleto_novo = Brcobranca::Boleto::Caixa.new
    expect { boleto_novo.codigo_barras }.to raise_error(Brcobranca::BoletoInvalido)
  end

  it 'Tamanho do número de convênio deve ser de 6 dígitos' do
    boleto_novo = Brcobranca::Boleto::Caixa.new @valid_attributes.merge(:convenio => '1234567')
    expect(boleto_novo).not_to be_valid
  end

  it 'Número do convênio deve ser preenchido com zeros à esquerda quando menor que 6 dígitos' do
    boleto_novo = Brcobranca::Boleto::Caixa.new @valid_attributes.merge(:convenio => '12345')
    expect(boleto_novo.convenio).to eq('012345')
    expect(boleto_novo).to be_valid
  end

  it 'Tamanho da carteira deve ser de 2 dígitos' do
    boleto_novo = Brcobranca::Boleto::Caixa.new @valid_attributes.merge(:carteira => '145')
    expect(boleto_novo).not_to be_valid

    boleto_novo = Brcobranca::Boleto::Caixa.new @valid_attributes.merge(:carteira => '1')
    expect(boleto_novo).not_to be_valid
  end

  it 'Tamanho do número documento deve ser de 15 dígitos' do
    boleto_novo = Brcobranca::Boleto::Caixa.new @valid_attributes.merge(:numero_documento => '1234567891234567')
    expect(boleto_novo).not_to be_valid
  end

  it 'Número do documento deve ser preenchido com zeros à esquerda quando menor que 15 dígitos' do
    boleto_novo = Brcobranca::Boleto::Caixa.new @valid_attributes.merge(:numero_documento => '1')
    expect(boleto_novo.numero_documento).to eq('000000000000001')
    expect(boleto_novo).to be_valid
  end

  it "Montar nosso_numero_boleto" do
    boleto_novo = Brcobranca::Boleto::Caixa.new @valid_attributes
    expect(boleto_novo.nosso_numero_boleto).to eq("#{boleto_novo.carteira}" <<
                                              "#{boleto_novo.numero_documento}" <<
                                              "-#{boleto_novo.nosso_numero_dv}")
  end

  it "Montar agencia_conta_boleto" do
    boleto_novo = Brcobranca::Boleto::Caixa.new(@valid_attributes)

    expect(boleto_novo.agencia_conta_boleto).to eql("1825/245274-0")

    boleto_novo.convenio = "123456"
    expect(boleto_novo.agencia_conta_boleto).to eql("1825/123456-0")

    boleto_novo.agencia = "2030"
    boleto_novo.convenio = "654321"
    expect(boleto_novo.agencia_conta_boleto).to eql("2030/654321-9")
  end

  it "Busca logotipo do banco" do
    boleto_novo = Brcobranca::Boleto::Caixa.new
    expect(File.exist?(boleto_novo.logotipo)).to be_truthy
    expect(File.stat(boleto_novo.logotipo).zero?).to be_falsey
  end

  it "Gerar boleto nos formatos válidos com método to_" do
    @valid_attributes[:valor] = 135.00
    @valid_attributes[:data_documento] = Date.parse("2008-02-01")
    @valid_attributes[:dias_vencimento] = 2
    @valid_attributes[:numero_documento] = "000000077700168"
    boleto_novo = Brcobranca::Boleto::Caixa.new(@valid_attributes)
    %w| pdf jpg tif png |.each do |format|
      file_body=boleto_novo.send("to_#{format}".to_sym)
      tmp_file=Tempfile.new("foobar." << format)
      tmp_file.puts file_body
      tmp_file.close
      expect(File.exist?(tmp_file.path)).to be_truthy
      expect(File.stat(tmp_file.path).zero?).to be_falsey
      expect(File.delete(tmp_file.path)).to eql(1)
      expect(File.exist?(tmp_file.path)).to be_falsey
    end
  end

  it "Gerar boleto nos formatos válidos" do
    @valid_attributes[:valor] = 135.00
    @valid_attributes[:data_documento] = Date.parse("2008-02-01")
    @valid_attributes[:dias_vencimento] = 2
    @valid_attributes[:numero_documento] = "000000077700168"
    boleto_novo = Brcobranca::Boleto::Caixa.new(@valid_attributes)
    %w| pdf jpg tif png |.each do |format|
      file_body=boleto_novo.to(format)
      tmp_file=Tempfile.new("foobar." << format)
      tmp_file.puts file_body
      tmp_file.close
      expect(File.exist?(tmp_file.path)).to be_truthy
      expect(File.stat(tmp_file.path).zero?).to be_falsey
      expect(File.delete(tmp_file.path)).to eql(1)
      expect(File.exist?(tmp_file.path)).to be_falsey
    end
  end

end
