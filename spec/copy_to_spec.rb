require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "COPY TO" do
  before(:each) do
    ActiveRecord::Base.connection.execute %{
      TRUNCATE TABLE test_models;
      SELECT setval('test_models_id_seq', 1, false);
}
    TestModel.create :data => 'test data 1'
  end

  describe ".copy_to_string" do
    context "with no options" do
      subject{ TestModel.copy_to_string }
      it{ should == File.open('spec/fixtures/comma_with_header.csv', 'r').read }
    end

    context "with tab as delimiter" do
      subject{ TestModel.copy_to_string :delimiter => "\t" }
      it{ should == File.open('spec/fixtures/tab_with_header.csv', 'r').read }
    end
  end

  describe ".copy_to_enumerator" do
    before(:each) do
      TestModel.create :data => 'test data 2'
      TestModel.create :data => 'test data 3'
      TestModel.create :data => 'test data 4'
    end

    context "with no options" do
      subject{ TestModel.copy_to_enumerator.to_a }
      it{ should == File.open('spec/fixtures/comma_with_header_multi.csv', 'r').read.lines }
    end

    context "with tab as delimiter" do
      subject{ TestModel.copy_to_enumerator(:delimiter => "\t").to_a }
      it{ should == File.open('spec/fixtures/tab_with_header_multi.csv', 'r').read.lines }
    end

    context "with many records" do
      context "enumerating in batches" do
        subject{ TestModel.copy_to_enumerator(:buffer_lines => 2).to_a }
        it do
          expected = []
          File.open('spec/fixtures/comma_with_header_multi.csv', 'r').read.lines.each_slice(2){|s| expected << s.join }
          should == expected
        end
      end

      context "excluding some records via a scope" do
        subject{ TestModel.where("data not like '%3'").copy_to_enumerator.to_a }
        it{ should == File.open('spec/fixtures/comma_with_header_and_scope.csv', 'r').read.lines }
      end
    end
  end

  describe ".copy_to" do
    it "should copy and pass data to block if block is given and no path is passed" do
      File.open('spec/fixtures/comma_with_header.csv', 'r') do |f|
        TestModel.copy_to do |row|
          row.should == f.readline
        end
      end
    end

    it "should copy to disk if block is not given and a path is passed" do
      TestModel.copy_to '/tmp/export.csv'
      File.open('spec/fixtures/comma_with_header.csv', 'r') do |fixture|
        File.open('/tmp/export.csv', 'r') do |result|
          result.read.should == fixture.read
        end
      end
    end

    it "should raise exception if I pass a path and a block simultaneously" do
      lambda do
        TestModel.copy_to('/tmp/bogus_path') do |row|
        end
      end.should raise_error
    end
  end
end
