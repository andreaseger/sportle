describe Parser do
  context 'when parseSchedule' do
    context "#full_distance" do
      it "should return the schedules full distance" do
        schedule = "200m einschwimmen\n2x200m Lagen\n4x100m Kraul\n  50m Ruecken\n300m ausschwimmen"
        Parser.parseSchedule(schedule)[:full_distance].should == 1500
      end
      it "should work with another schedule" do
        schedule = "400m einschwimmen\n2x200m Lagen\r\n4x100m Kraul\n  50m Ruecken\r\n300m ausschwimmen"
        Parser.parseSchedule(schedule)[:full_distance].should == 1700
      end
      it "should work with \\r as lineend" do
        schedule = "400m einschwimmen\r2x200m Lagen\r4x100m Kraul\r  50m Ruecken\r300m ausschwimmen"
        Parser.parseSchedule(schedule)[:full_distance].should == 1700
      end
    end
    context "#items" do
      it "should return the number of real - non info - items" do
        schedule = "400m einschwimmen\n2x200m Lagen\r\n4x100m Kraul\n  50m Ruecken\r\n300m ausschwimmen"
        Parser.parseSchedule(schedule)[:items].should == 5
      end
      it "should return the number of real - non info - items" do
        schedule = "400m einschwimmen\n  50m Ruecken\r\n300m ausschwimmen"
        Parser.parseSchedule(schedule)[:items].should == 3
      end
      it "should return the number of real - non info - items" do
        schedule = "400m einschwimmen\n  50m Ruecken\n-blas\n300m ausschwimmen"
        Parser.parseSchedule(schedule)[:items].should == 3
      end
    end
  end
  context "when parseItem" do
    context "when itemlevel is 0" do
      it "should find the distance" do
        item = Item.new(:text => "200m Lagen", :outer => nil, :inner => nil, :distance => 200, :level => 0)
        Parser.parseItem(item.text).should == item
      end
      it "should find the first multiplicator" do
        item = Item.new(:text => "2x200m Lagen", :outer => 2, :inner => nil, :distance => 200, :level => 0)
        Parser.parseItem(item.text).should == item
      end
      it "should find both multiplicators" do
        item = Item.new(:text => "2x5x200m Lagen", :outer => 2, :inner => 5, :distance => 200, :level => 0)
        Parser.parseItem(item.text).should == item
      end
    end
    context "when itemlevel is 1" do
      it "should find the distance" do
        item = Item.new(:text => "  200m Lagen", :outer => nil, :inner => nil, :distance => 200, :level => 1)
        Parser.parseItem(item.text).should == item
      end
      it "should find the first multiplicator" do
        item = Item.new(:text => "  2x200m Lagen", :outer => nil, :inner => 2, :distance => 200, :level => 1)
        Parser.parseItem(item.text).should == item
      end
    end
  end
  context "when full_schedule_distance" do
    before do
      @i1 = Item.new(:level => 0, :distance => 400)
      @i2 = Item.new(:level => 0, :outer => 2, :distance => 800)
      @i3 = Item.new(:level => 0, :outer => 3, :distance => 500)
      @i4 = Item.new(:level => 1, :distance => 50)
      @i5 = Item.new(:level => 0, :inner => 5, :outer => 3, :distance => 100)
      @i6 = Item.new(:level => 2, :distance => 50)
      @i7 = Item.new(:inner => 2, :distance => 50, :level => 1)
    end
    
    it "should calculate the right full distance if all items lvl0" do
      items = [@i1, @i2, @i3]
      Parser.full_schedule_distance(items).should eql(3500)
    end
    it "should calculate the right full distance if there is a lvl1 item" do
      items = [@i1, @i2, @i3, @i4]
      Parser.full_schedule_distance(items).should eql(3650)
    end
    it "should calculate the right full distance if there is a lvl2 item" do
      items = [@i5, @i6]
      Parser.full_schedule_distance(items).should eql(2250)
    end
    it "should calculate the right full distance if there is a lvl1 item with inner multi" do
      items = [@i5, @i7]
      Parser.full_schedule_distance(items).should eql(1800)
    end
    it "should calculate the right full distance if there is a lvl1 item where the parent item has no multi" do
      items = [@i1, @i4]
      Parser.full_schedule_distance(items).should eql(450)
    end
    it "should calculate the right full distance if there is a lvl2 item where the parent item has no inner multi" do
      items = [@i3, @i6]
      Parser.full_schedule_distance(items).should eql(1650)
    end
    it "should calculate the right full distance if there is a mix of all the above" do
      items = [@i1, @i2, @i3, @i4, @i5, @i6, @i7]
      Parser.full_schedule_distance(items).should eql(6200)
    end
    it "should calculate the right full distance if there is a mix of all the above2" do
      items = [@i1, @i2, @i3, @i4, @i5, @i6, @i7, @i3, @i6, @i1, @i4]
      Parser.full_schedule_distance(items).should eql(8300)
    end
  end
end
