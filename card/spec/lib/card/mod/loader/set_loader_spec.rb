# -*- encoding : utf-8 -*-

RSpec.describe Card::Mod::Loader::SetLoader do
  let(:mod_dirs) do
    path = File.expand_path "../../../../../support/test_mods", __FILE__
    Card::Mod::Dirs.new path
  end

  it 'initializes the load strategy' do
    expect(Card::Mod::LoadStrategy::Eval).to receive(:new)
    described_class.new mod_dirs, load_strategy: :eval
  end

  it "load mods" do
    described_class.new(mod_dirs).load
    expect(Card::Set.const_defined?("All::TestSet")).to be_truthy
    expect(Card.take.test_method).to eq "works"
  end
end
