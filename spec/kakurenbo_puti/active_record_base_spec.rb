require 'spec_helper'

describe KakurenboPuti::ActiveRecordBase do
  define_active_record_model :NormalModel do; end

  define_active_record_model :SoftDeleteModel do |t|
    t.datetime :soft_destroyed_at
    t.datetime :deleted_at
  end

  define_active_record_model :SoftDeleteChild do |t|
    t.integer :soft_delete_model_id
    t.integer :normal_model_id
    t.datetime :soft_destroyed_at
  end

  let :model_class do
    options_cache = model_class_options
    SoftDeleteModel.tap do |klass|
      klass.class_eval do
        soft_deletable options_cache
        has_many :soft_delete_children

        before_soft_destroy :cb_mock
        after_soft_destroy  :cb_mock

        before_restore      :cb_mock
        after_restore       :cb_mock

        define_method(:cb_mock) { true }
      end
    end
  end

  let :child_class do
    options_cache = child_class_options
    SoftDeleteChild.tap do |klass|
      klass.class_eval do
        soft_deletable options_cache
        belongs_to :soft_delete_model
        belongs_to :normal_model
      end
    end
  end

  let :model_class_options do
    {}
  end

  let :child_class_options do
    { dependent_associations: [:soft_delete_model, :normal_model] }
  end

  let! :normal_model_instance do
    NormalModel.create!
  end

  let! :model_instance do
    model_class.create!
  end

  let! :child_instance do
    child_class.create!(soft_delete_model: model_instance, normal_model: normal_model_instance)
  end

  describe '.soft_delete_column' do
    # soft_deletable に引数を指定しない場合
    context "No option is passed as an argument of 'soft_deletable'" do
      # 論理削除の対象となるデフォルトのカラム名を返す
      it 'returns default column name to be soft-deleted' do
        expect(model_class.soft_delete_column).to eq(:soft_destroyed_at)
      end
    end

    # soft_deletable の引数にオプション 'column' が指定されている場合
    context "when the option 'column' is present and the option is passed as an argument of 'soft_deletable'" do
      let :model_class_options do
        { column: :deleted_at }
      end

      # オプションに指定されているカラム名を返す
      it 'returns column name given to option' do
        expect(model_class.soft_delete_column).to eq(:deleted_at)
      end
    end
  end

  describe '#soft_delete_column' do
    # soft_deletable に引数を指定しない場合
    context "No option is passed as an argument of 'soft_deletable'" do
      # 論理削除の対象となるデフォルトのカラム名を返す
      it 'returns default column name to be soft-deleted' do
        expect(model_instance.soft_delete_column).to eq(:soft_destroyed_at)
      end
    end

    # soft_deletable の引数にオプション 'column' が指定されている場合
    context "when the option 'column' is present and the option is passed as an argument of 'soft_deletable'" do
      let :model_class_options do
        { column: :deleted_at }
      end

      # オプションに指定されているカラム名を返す
      it 'returns column name given to option' do
        expect(model_instance.soft_delete_column).to eq(:deleted_at)
      end
    end
  end

  describe '#soft_delete_column' do
    # soft_deletable に引数を指定しない場合
    context "No option is passed as an argument of 'soft_deletable'" do
      # 論理削除の対象となるデフォルトのカラム名を返す
      it 'returns default column name to be soft-deleted' do
        expect(model_instance.soft_delete_column).to eq(:soft_destroyed_at)
      end
    end

    # soft_deletable の引数にオプション 'column' が指定されている場合
    context "when the option 'column' is present and the option is passed as an argument of 'soft_deletable'" do
      let :model_class_options do
        { column: :deleted_at }
      end

      # オプションに指定されているカラム名を返す
      it 'returns column name given to option' do
        expect(model_instance.soft_delete_column).to eq(:deleted_at)
      end
    end
  end

  describe '.only_soft_destroyed' do
    subject do
      child_class.only_soft_destroyed
    end

    # 論理削除されているレコードのみのリレーションを返す
    it 'returns a relation only with soft-deleted records.' do
      expect {
        child_instance.soft_destroy!
      }.to change {
        subject.count
      }.by(1)
    end

    # 親レコードが論理削除されている場合
    context 'When the instance of parent_class is soft-deleted' do
      # soft_deletable に引数が指定されていない場合
      context "No option is passed as an argument of 'soft_deletable'" do
        # 論理削除されているレコードのみのリレーションを返す．
        # 親レコードが論理削除されているレコードも含む．
        it 'returns a relation only with soft-deleted records. Records of which parents are soft-deleted are included.' do
          expect {
            child_instance.soft_delete_model.soft_destroy!
          }.to change {
            subject.count
          }.by(1)
        end
      end

      # soft_deletable の引数にオプション 'dependent_associations' が指定されていて，空の配列である場合
      context "when the option 'dependent_associations' is an empty array and the option is passed as an argument of 'soft_deletable'" do
        let :child_class_options do
          { dependent_associations: [] }
        end

        # 論理削除されているレコードのみのリレーションを返す．
        # 親レコードが論理削除されているレコードも含む．
        it 'returns a relation only with soft-deleted records. Records of which parents are soft-deleted are not included.' do
          expect {
            child_instance.soft_delete_model.soft_destroy!
          }.not_to change {
            subject.count
          }
        end
      end
    end

    # 親レコードが物理削除されている場合
    context 'When the instance of parent_class is hard-deleted' do
      # soft_deletable に引数が指定されていない場合
      context "No option is passed as an argument of 'soft_deletable'" do
        # 論理削除されているレコードのみのリレーションを返す．
        # 親レコードが論理削除されているレコードも含む．
        it 'returns a relation only with soft-deleted records. Records of which parents are soft-deleted are included.' do
          expect {
            child_instance.normal_model.destroy!
          }.to change {
            subject.count
          }.by(1)
        end
      end

      # soft_deletable の引数にオプション 'dependent_associations' が指定されていて，空の配列である場合
      context "when the option 'dependent_associations' is an empty array and the option is passed as an argument of 'soft_deletable'" do
        let :child_class_options do
          { dependent_associations: [] }
        end

        # 論理削除されているレコードのみのリレーションを返す．
        # 親レコードが論理削除されているレコードは含まない．
        it 'returns a relation only with soft-deleted records. Records of which parents are soft-deleted are not included.' do
          expect {
            child_instance.normal_model.destroy!
          }.not_to change {
            subject.count
          }
        end
      end
    end
  end

  describe '.without_soft_destroyed' do
    # soft_deletable の引数にオプション 'dependent_associations' が指定されていて，has_many に指定されているリレーションの名称が含まれる場合
    context "when the option 'dependent_associations' is an array and an association name as an argument of `has_many` is included" do
      subject do
        model_class.without_soft_destroyed
      end

      let :model_class_options do
        { dependent_associations: [:soft_delete_children] }
      end

      # RuntimeError が発生する
      it 'raises RuntimeError' do
        expect { subject }.to raise_error(RuntimeError) do |e|
          expect(e.message).to eq('dependent association is usable only in `belongs_to`.')
        end
      end
    end

    subject do
      child_class.without_soft_destroyed
    end

    # 論理削除されていないレコードのみのリレーションを返す．
    it 'returns a relation without soft-deleted records.' do
      expect {
        child_instance.soft_destroy!
      }.to change {
        subject.count
      }.by(-1)
    end

    # 親レコードが論理削除されている場合
    context 'When the instance of parent_class is soft-deleted' do
      # soft_deletable に引数が指定されていない場合
      context "No option is passed as an argument of 'soft_deletable'" do
        # 論理削除されていないレコードのみのリレーションを返す．
        # 親レコードが論理削除されているレコードは含まない．
        it 'returns a relation without soft-deleted records. Records of which parents are soft-deleted are not included.' do
          expect {
            child_instance.soft_delete_model.soft_destroy!
          }.to change {
            subject.count
          }.by(-1)
        end
      end

      # soft_deletable の引数にオプション 'dependent_associations' が指定されていて，空の配列である場合
      context "when the option 'dependent_associations' is an empty array and the option is passed as an argument of 'soft_deletable'" do
        let :child_class_options do
          { dependent_associations: [] }
        end

        # 論理削除されていないレコードのみのリレーションを返す．
        # 親レコードが論理削除されているレコードも含む．
        it 'returns a relation without soft-deleted records. Records of which parents are soft-deleted are included.' do
          expect {
            child_instance.soft_delete_model.soft_destroy!
          }.not_to change {
            subject.count
          }
        end
      end
    end

    # 親レコードが物理削除されている場合
    context 'When the instance of parent_class is hard-deleted' do
      # soft_deletable に引数が指定されていない場合
      context "No option is passed as an argument of 'soft_deletable'" do
        # 論理削除されていないレコードのみのリレーションを返す．
        # 親レコードが論理削除されているレコードは含まない．
        it 'returns a relation without soft-deleted records. Records of which parents are soft-deleted are not included.' do
          expect {
            child_instance.normal_model.destroy!
          }.to change {
            subject.count
          }.by(-1)
        end
      end

      # soft_deletable の引数にオプション 'dependent_associations' が指定されていて，空の配列である場合
      context "when the option 'dependent_associations' is an empty array and the option is passed as an argument of 'soft_deletable'" do
        let :child_class_options do
          { dependent_associations: [] }
        end

        # 論理削除されていないレコードのみのリレーションを返す．
        # 親レコードが論理削除されているレコードも含む．
        it 'returns a relation without soft-deleted records. Records of which parents are soft-deleted are included.' do
          expect {
            child_instance.normal_model.destroy!
          }.not_to change {
            subject.count
          }
        end
      end
    end
  end

  describe '#restore' do
    before :each do
      model_instance.soft_destroy
    end

    subject do
      model_instance.restore
    end

    it 'restores soft-deleted record.' do
      expect {
        subject
      }.to change {
        model_class.without_soft_destroyed.count
      }.by(1)
    end

    it 'returns true' do
      expect(subject).to be(true)
    end

    it 'runs callbacks.' do
      expect(model_instance).to receive(:cb_mock).twice
      subject
    end

    context 'When ActiveRecord::ActiveRecordError is raised in #update_column.' do
      before :each do
        allow_any_instance_of(model_class).to receive(:update_column) { raise ActiveRecord::ActiveRecordError }
      end

      it 'returns false' do
        expect(subject).to be(false)
      end
    end
  end

  describe '#restore!' do
    subject do
      model_instance.restore!
    end

    it 'returns self' do
      expect(subject).to eq(model_instance)
    end

    it 'runs callbacks.' do
      expect(model_instance).to receive(:cb_mock).twice
      subject
    end

    context 'When ActiveRecord::ActiveRecordError is raised in #update_column.' do
      before :each do
        allow_any_instance_of(model_class).to receive(:update_column) { raise ActiveRecord::ActiveRecordError }
      end

      it 'raises ActiveRecord::ActiveRecordError.' do
        expect{ subject }.to raise_error(ActiveRecord::ActiveRecordError)
      end
    end
  end

  describe '#soft_destroy' do
    subject do
      model_instance.soft_destroy
    end

    it 'soft-deletes record.' do
      expect {
        subject
      }.to change {
        model_class.without_soft_destroyed.count
      }.by(-1)
    end

    it 'returns true' do
      expect(subject).to be(true)
    end

    it 'runs callbacks.' do
      expect(model_instance).to receive(:cb_mock).twice
      subject
    end

    context 'When an exception is raised in #touch.' do
      before :each do
        allow_any_instance_of(model_class).to receive(:touch) { raise ActiveRecord::ActiveRecordError }
      end

      it 'returns false' do
        expect(subject).to be(false)
      end
    end
  end

  describe '#soft_destroy!' do
    subject do
      model_instance.soft_destroy!
    end

    it 'returns self.' do
      expect(subject).to eq(model_instance)
    end

    it 'runs callbacks.' do
      expect(model_instance).to receive(:cb_mock).twice
      subject
    end

    context 'When ActiveRecord::ActiveRecordErrorn is raised in #touch.' do
      before :each do
        allow_any_instance_of(model_class).to receive(:touch) { raise ActiveRecord::ActiveRecordError }
      end

      it 'raises ActiveRecordError.' do
        expect{ subject }.to raise_error(ActiveRecord::ActiveRecordError)
      end
    end
  end

  describe '#soft_destroyed?' do
    subject do
      model_instance.soft_destroyed?
    end

    it 'returns false' do
      expect(subject).to be(false)
    end

    context 'When model is soft-deleted' do
      before :each do
        model_instance.soft_destroy!
      end

      it 'returns true' do
        expect(subject).to be(true)
      end
    end
  end

  describe '.soft_destroy_all' do
    subject do
      model_class.soft_destroy_all
    end
    let!(:model_instance) { model_class.create! }

    it 'soft-deletes records' do
      expect {
        subject
      }.to change {
        model_class.without_soft_destroyed.count
      }.to(0)
    end

    context 'with conditions' do
      subject do
        model_class.soft_destroy_all(id: model_instance.id)
      end

      it 'soft-deletes records' do
        expect {
          subject
        }.to change {
          model_class.without_soft_destroyed.count
        }.to(0)
      end
    end
  end
end
