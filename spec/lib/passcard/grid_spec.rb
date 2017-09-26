RSpec.describe Passcard::Grid do
  let(:arr1) {['ABCDE', 'FGHIJ', 'KLMNO', 'PQRST', 'UVWXY'].map(&:chars)}
  let(:arr2) {['AFKPU', 'BGLQV', 'CHMRW', 'DINSX', 'EJOTY'].map(&:chars)}
  let(:grid1){ described_class.new(arr1) }
  let(:grid2){ described_class.new(arr2) }

  describe "#rows_at" do
    it "returns an instance of Passcard::Grid" do
      expect(grid1.rows_at(0)).to be_a_passcard_grid.with_size(1,5)
    end

    it "returns rows at particular indices" do
      expect(grid1.rows_at( 0).to_str).to eq "ABCDE"
      expect(grid1.rows_at( 2).to_str).to eq "KLMNO"
      expect(grid1.rows_at(-2).to_str).to eq "PQRST"
    end

    it "treats rows as a continuous infinite space" do
      expect(grid1.rows_at( 5).to_str).to eq "ABCDE"
      expect(grid1.rows_at(-8).to_str).to eq "KLMNO"
      expect(grid1.rows_at( 100001).to_str).to eq "FGHIJ"
      expect(grid1.rows_at(-100001).to_str).to eq "UVWXY"
    end

    it "returns rows at multiple indices" do
      expect(grid1.rows_at( 0,-1).to_str).to eq "ABCDEUVWXY"
      expect(grid1.rows_at( 2,-3).to_str).to eq "KLMNOKLMNO"
      expect(grid1.rows_at( -4,4).to_str).to eq "FGHIJUVWXY"
      expect(grid1.rows_at(1,3,4).to_str).to eq "FGHIJPQRSTUVWXY"
      expect(grid1.rows_at(1,3,5).to_str).to eq "FGHIJPQRSTABCDE"
    end

    it "returns rows at indices specified by range" do
      expect(grid1.rows_at(4..6).to_str).to eq "UVWXYABCDEFGHIJ"
      expect(grid1.rows_at(-11..-9).to_str).to eq "UVWXYABCDEFGHIJ"
    end

    it "returns rows at indices specified by arrays" do
      expect(grid1.rows_at([4,5,6]).to_str).to eq "UVWXYABCDEFGHIJ"
      expect(grid1.rows_at([-11,-8,-9]).to_str).to eq "UVWXYKLMNOFGHIJ"
    end

    it "returns rows at indices specified by a mix of above ways" do
      subgrid = grid1.rows_at(0..4,-5..0,[1,2,3],[-1,-10,-14,12],3..5,-24..-21)
      expect(subgrid.to_str).to eq grid1.to_str * 5
    end

    it "delegates #[] to #rows_at" do
      expect(grid1).to receive(:rows_at).with(:whatever)
      grid1[:whatever]
    end
  end

  describe "#cols_at" do
    it "returns an instance of Passcard::Grid" do
      expect(grid2.cols_at(0)).to be_a_passcard_grid.with_size(5,1)
    end

    it "returns columns at particular indices" do
      expect(grid2.cols_at( 0).to_str).to eq "ABCDE"
      expect(grid2.cols_at( 2).to_str).to eq "KLMNO"
      expect(grid2.cols_at(-2).to_str).to eq "PQRST"
    end

    it "treats columns as a continuous infinite space" do
      expect(grid2.cols_at( 5).to_str).to eq "ABCDE"
      expect(grid2.cols_at(-8).to_str).to eq "KLMNO"
      expect(grid1.rows_at( 100001).to_str).to eq "FGHIJ"
      expect(grid1.rows_at(-100001).to_str).to eq "UVWXY"
    end

    it "returns columns at multiple indices" do
      expect(grid2.cols_at( 0,-1).to_str).to  eq "AUBVCWDXEY"
      expect(grid2.cols_at( 0,-1).to_vstr).to eq "ABCDEUVWXY"
      expect(grid2.cols_at( 2,-3).to_vstr).to eq "KLMNOKLMNO"
      expect(grid2.cols_at( -4,4).to_vstr).to eq "FGHIJUVWXY"
      expect(grid2.cols_at(1,3,4).to_vstr).to eq "FGHIJPQRSTUVWXY"
      expect(grid2.cols_at(1,3,5).to_vstr).to eq "FGHIJPQRSTABCDE"
    end

    it "returns columns at indices specified by range" do
      expect(grid2.cols_at(4..6).to_vstr).to eq "UVWXYABCDEFGHIJ"
      expect(grid2.cols_at(-11..-9).to_vstr).to eq "UVWXYABCDEFGHIJ"
    end

    it "returns columns at indices specified by arrays" do
      expect(grid2.cols_at([4,5,6]).to_vstr).to eq "UVWXYABCDEFGHIJ"
      expect(grid2.cols_at([-11,-8,-9]).to_vstr).to eq "UVWXYKLMNOFGHIJ"
    end

    it "returns columns at indices specified by a mix of above ways" do
      subgrid = grid2.cols_at(0..4,-5..0,[1,2,3],[-1,-10,-14,12],3..5,-24..-21)
      expect(subgrid.to_vstr).to eq grid2.to_vstr * 5
    end
  end

  describe "#at" do
    it "delegates to methods: #rows_at, #cols_at" do
      expect_any_instance_of(Passcard::Grid).to receive(:cols_at).once.and_call_original
      expect_any_instance_of(Passcard::Grid).to receive(:rows_at).once.and_call_original
      expect(grid1.at(rows: [1, 2], cols:[3, 4]).to_str).to eq "IJNO"
    end

    it "returns the complete row/column when corresp. column/row indices are empty" do
      expect_any_instance_of(Passcard::Grid).to receive(:rows_at).twice.and_call_original
      expect(grid1.at(rows: [1, 2]).to_str).to eq "FGHIJKLMNO"
      expect(grid1.at(rows: [1, 2], cols: []).to_str).to eq "FGHIJKLMNO"
      expect_any_instance_of(Passcard::Grid).to receive(:cols_at).twice.and_call_original
      expect(grid1.at(cols: [1,-3]).to_str).to eq "BCGHLMQRVW"
      expect(grid1.at(cols: [1,-3], rows: []).to_str).to eq "BCGHLMQRVW"
    end

    it "returns itself (main grid) with empty indices" do
      expect_any_instance_of(Passcard::Grid).not_to receive(:cols_at)
      expect_any_instance_of(Passcard::Grid).not_to receive(:rows_at)
      expect(grid1.at(rows: [], cols: [])).to eq grid1
    end
  end

  describe "#slice" do
    it "allows getting subgrid from a given coordinate to another" do
      subgrid = grid1.slice([0,0], [5,5])
      expect(subgrid).to be_a_passcard_grid.with_size(5, 5)

      subgrid = grid1.slice([-130, -143], [-123, -128])
      expect(subgrid).to be_a_passcard_grid.with_size(7, 15)

      subgrid = grid1.slice([-123, -128], [-130, -143])
      expect(subgrid).to be_a_passcard_grid.with_size(0, 0)
    end

    it "delegates to methods: #rows_at, #cols_at" do
      expect_any_instance_of(Passcard::Grid).to receive(:rows_at).once.and_call_original
      expect_any_instance_of(Passcard::Grid).to receive(:cols_at).once.and_call_original
      expect(grid1.slice([15,15], [20,20]).size).to eq [5,5]
    end
  end

  describe "#transpose" do
    it "allows transposing of the grid coverting rows to cols and vice versa" do
      expect(grid1.transpose).to eq grid2
      expect(grid1.transpose.transpose).to eq grid1
    end
  end

  describe "#rotate" do
    it "allows rotating the grid rows" do
      expect(grid1.rotate(r:  1)).to eq grid1.rows_at( 1...grid1.row_size+1)
      expect(grid1.rotate(r:  3)).to eq grid1.rows_at( 3...grid1.row_size+3)
      expect(grid1.rotate(r: -1)).to eq grid1.rows_at(-1...grid1.row_size-1)
    end

    it "allows rotating the grid columns" do
      expect(grid1.rotate(c:  1)).to eq grid1.cols_at( 1...grid1.col_size+1)
      expect(grid1.rotate(c:  3)).to eq grid1.cols_at( 3...grid1.col_size+3)
      expect(grid1.rotate(c: -1)).to eq grid1.cols_at(-1...grid1.col_size-1)
    end

    it "allows rotating both grid rows and columns" do
      actual   = grid1.rotate(r: -2, c: -8)
      expected = grid1.rows_at(-2...grid1.row_size-2).cols_at(-8...grid1.col_size-8)
      expect(actual).to eq expected
    end
  end

  describe "#numeric?" do
    it "checks if a grid comprises of numbers only" do
      expect(Passcard::Grid.new([])).not_to be_numeric
      expect(Passcard::Grid.new([[0,1], [3,4]])).to be_numeric
      expect(Passcard::Grid.new([[0,1], ["A",4]])).not_to be_numeric
    end
  end

  describe "#alphanumeric?" do
    it "checks if a grid comprises of numbers and alphabets only" do
      expect(Passcard::Grid.new([])).not_to be_alphanumeric
      expect(Passcard::Grid.new([[0,1], [3,4]])).to be_alphanumeric
      expect(Passcard::Grid.new([[0,1], ["A",4]])).to be_alphanumeric
      expect(Passcard::Grid.new([["A","B"], ["C","D"]])).to be_alphanumeric
      expect(Passcard::Grid.new([["A","!"], ["C","D"]])).not_to be_alphanumeric
    end
  end

  describe "#numeric?" do
    it "checks if a grid comprises of numbers only" do
      expect(Passcard::Grid.new([])).not_to have_symbols
      expect(Passcard::Grid.new([[0,1],["A", "!"]])).to have_symbols
      expect(Passcard::Grid.new([[0,1],[2, 3]])).not_to have_symbols
      expect(Passcard::Grid.new([[0,1],["A", "B"]])).not_to have_symbols
    end
  end

  context "methods for common information about the grid" do
    it "provides information on grid size and length, etc." do
      expect(grid1.row_size).to eq 5
      expect(grid1.col_size).to eq 5
      expect(grid1.size).to eq [5,5]
      expect(grid1.length).to eq  25
    end
  end

  context "string conversion and inspection" do
    it "converts grid into a continous string by joining rows and columns" do
      expect(grid1.to_str ).to eq ('A'..'Y').to_a.join
      expect(grid2.to_vstr).to eq ('A'..'Y').to_a.join
    end

    it "converts grid into a string with linebreaks and spaces for printing" do
      expect(grid1.to_s.split("\n").length).to eq grid1.row_size
      expect(grid1.to_s.split("\n")[1]).to eq grid1.rows_at(1).to_a.join(" ")
    end

    it "allows normal printing for small grids and concise printing for large grids" do
      str = "A B C D E\nF G H I J\nK L M N O\nP Q R S T\nU V W X Y\n"
      expect{ grid1.print }.to output(str).to_stdout

      allow(grid1).to receive(:col_size).and_return 50
      str = "ABCDE\nFGHIJ\nKLMNO\nPQRST\nUVWXY\n"
      expect{ grid1.print }.to output(str).to_stdout
    end

    it "has an #inspect method for viewing information about the grid easily" do
      expect(Passcard::Grid.new([]).inspect).to eq 'Passcard::Grid[rows=0,cols=0,length=0]{""}'

      str = "Passcard::Grid[rows=5,cols=5,length=25]{\"#{('A'..'Y').to_a.join}\"}"
      expect(grid1.inspect).to eq str

      mgrid = Passcard::Grid.new([(0..9).to_a]*10)
      chars = "0123456789012345678901234567890123456...."
      str   = "Passcard::Grid[rows=10,cols=10,length=100]{\"#{chars}\"}"
      expect(mgrid.inspect).to eq str
    end
  end

  it "delegates some methods to its array and string representations" do
    expect(grid1.chars).to eq grid1.to_str.chars
    expect(grid1.take(2)).to eq grid1.rows_at(0,1).to_a
    expect{ grid1.unknown_method }.to raise_error NoMethodError
  end

  it "raises error when underlying array is not 2D array of chars" do
    valid = [ [], [[0,1],[1,0]], [[0,1,2],[1,2,3]],
      [['A','B'], ['C', 'D']], [[0, 1], ['A', 'B']] ]

    invalid = [ [0], [0, 1], ['A', 'B'], [0, [1,2]], [0, [1]],
      [[0,1], [0,1,2]], [[0,1], 0, 1], [[0,1], [1,11]],
      [['AB', 'A'], ['C', 'B']] ]

    valid.each{|arr| expect{ Passcard::Grid.new(arr) }.not_to raise_error}
    invalid.each{|arr| expect{ Passcard::Grid.new(arr) }.to raise_error(Passcard::Error)}
  end
end
