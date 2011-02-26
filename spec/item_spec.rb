describe Item do
  context 'when full_distance' do
    it 'should calculate the correct ex1' do
      item = Item.new(:inner => 5, :outer => 2, :distance => 100)
      item.full_distance.should eq 1000
    end
    it 'should calculate the correct ex2' do
      item = Item.new(:inner => 7, :outer => 3, :distance => 50)
      item.full_distance.should eq 1050
    end
    it 'should calculate the correct if inner is nil' do
      item = Item.new(:inner => nil, :outer => 5, :distance => 50)
      item.full_distance.should eq 250
    end
    it 'should calculate the correct if outer is nil' do
      item = Item.new(:inner => 5, :outer => nil, :distance => 50)
      item.full_distance.should eq 250
    end
    it 'should calculate the correct if inner and outer is nil' do
      item = Item.new(:inner => nil, :outer => nil, :distance => 50)
      item.full_distance.should eq 50
    end
  end
end
