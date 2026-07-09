require 'spec_helper'

describe MediaFilesController do
  let(:admin_user) { create :admin_user }
  let(:media_file) { create :media_file }

  describe '#index' do
    it 'prepares sorters' do
      get :index, session: { user_id: admin_user.id }

      expect(assigns[:sorters]).to eq [
        ['created_at (asc)', 'created_at_asc'],
        ['created_at (desc)', 'created_at_desc'],
        ['media_type (asc)', 'media_type_asc'],
        ['media_type (desc)', 'media_type_desc'],
        ['uploader (asc)', 'uploader_asc'],
        ['uploader (desc)', 'uploader_desc'],
        ['size (asc)', 'size_asc'],
        ['size (desc)', 'size_desc']
      ]
    end

    context 'filtering' do
      it 'filters correctly by missing conversion status' do
        allow(Settings).to receive(:zencoder_audio_output_formats) do
          OpenStruct.new(
            vorbis: OpenStruct.new(audio_codec: 'vorbis'),
            wma: OpenStruct.new(audio_codec: 'wma'),
            mp3: OpenStruct.new(audio_codec: 'mp3')
          )
        end
        mf1 = create(
          :media_file_for_audio_with_zencoder_jobs,
          filename: 'foo.ogg',
          previews_attrs: [
            { conversion_profile: 'vorbis' },
            { conversion_profile: 'wma' }
          ]
        )
        mf2 = create(
          :media_file_for_audio_with_zencoder_jobs,
          filename: 'foo.ogg',
          previews_attrs: [
            { conversion_profile: 'vorbis' },
            { conversion_profile: 'mp3' }
          ]
        )
        mf3 = create(
          :media_file_for_audio_with_zencoder_jobs,
          filename: 'foo.ogg',
          previews_attrs: [
            { conversion_profile: 'vorbis' },
            { conversion_profile: 'wma' },
            { conversion_profile: 'wma' }
          ]
        )
        # media file with all needed formats
        create(
          :media_file_for_audio_with_zencoder_jobs,
          filename: 'foo.ogg',
          previews_attrs: [
            { conversion_profile: 'vorbis' },
            { conversion_profile: 'wma' },
            { conversion_profile: 'mp3' }
          ]
        )
        # media file with submitted zencoder job
        create(
          :media_file_for_audio_with_zencoder_jobs,
          filename: 'foo.ogg',
          previews_attrs: [
            { conversion_profile: 'vorbis' }
          ],
          zencoder_job_attrs: {
            state: 'submitted'
          }
        )

        get(
          :index,
          params: {
            filter: {
              search_term: 'foo.ogg',
              conversion_status: :missing
            }
          },
          session: { user_id: admin_user.id }
        )

        expect(assigns[:media_files]).to match_array [mf1, mf2, mf3]
      end

      it 'filters correctly by failed conversion status' do
        mf = create(
          :media_file_for_movie_with_zencoder_jobs,
          filename: 'foo.mov',
          states: [:finished, :failed]
        )
        create(
          :media_file_for_movie_with_zencoder_jobs,
          filename: 'foo.mov',
          states: [:failed, :finished]
        )

        get(
          :index,
          params: {
            filter: {
              search_term: 'foo.mov',
              conversion_status: :failed
            }
          },
          session: { user_id: admin_user.id }
        )

        expect(assigns[:media_files]).to eq [mf]
      end
    end

    describe 'sorting' do
      context 'ascending' do
        it 'sorts correctly by uploader' do
          mf1 = create(:media_file,
                       filename: 'foo.jpg',
                       extension: 'jpg',
                       uploader: prepare_uploader('a', 'c'))
          mf2 = create(:media_file,
                       filename: 'foo.jpg',
                       extension: 'jpg',
                       uploader: prepare_uploader('b', 'c'))
          mf3 = create(:media_file,
                       filename: 'foo.jpg',
                       extension: 'jpg',
                       uploader: prepare_uploader('a', 'b'))

          get(
            :index,
            params: {
              filter: { search_term: 'foo' },
              sort_by: :uploader_asc
            },
            session: { user_id: admin_user.id }
          )

          expect(assigns[:media_files]).to eq [mf3, mf1, mf2]
        end

        it 'sorts correctly by media_type' do
          uploader = create(:user)
          mf1 = create(:media_file_for_other, uploader: uploader)
          mf2 = create(:media_file_for_document, uploader: uploader)
          mf3 = create(:media_file_for_audio, uploader: uploader)

          get(
            :index,
            params: {
              filter: { search_term: uploader.id },
              sort_by: :media_type_asc },
            session: { user_id: admin_user.id }
          )

          expect(assigns[:media_files]).to eq [mf3, mf2, mf1]
        end

        it 'sorts correctly by size' do
          uploader = create(:user)
          mf1 = create(:media_file_for_audio, size: 1500, uploader: uploader)
          mf2 = create(:media_file_for_audio, size: 3000, uploader: uploader)
          mf3 = create(:media_file_for_audio, size: 100, uploader: uploader)

          get(
            :index,
            params: { filter: { search_term: uploader.id }, sort_by: :size_asc },
            session: { user_id: admin_user.id }
          )

          expect(assigns[:media_files]).to eq [mf3, mf1, mf2]
        end
      end

      context 'descending' do
        it 'sorts correctly by uploader' do
          mf1 = create(:media_file,
                       filename: 'foo.jpg',
                       extension: 'jpg',
                       uploader: prepare_uploader('a', 'c'))
          mf2 = create(:media_file,
                       filename: 'foo.jpg',
                       extension: 'jpg',
                       uploader: prepare_uploader('b', 'c'))
          mf3 = create(:media_file,
                       filename: 'foo.jpg',
                       extension: 'jpg',
                       uploader: prepare_uploader('a', 'b'))

          get(
            :index,
            params: {
              filter: { search_term: 'foo' },
              sort_by: :uploader_desc
            },
            session: { user_id: admin_user.id }
          )

          expect(assigns[:media_files]).to eq [mf2, mf1, mf3]
        end

        it 'sorts correctly by media_type' do
          uploader = create(:user)
          mf1 = create(:media_file_for_other, uploader: uploader)
          mf2 = create(:media_file_for_document, uploader: uploader)
          mf3 = create(:media_file_for_audio, uploader: uploader)

          get(
            :index,
            params: {
              filter: { search_term: uploader.id },
              sort_by: :media_type_desc },
            session: { user_id: admin_user.id }
          )

          expect(assigns[:media_files]).to eq [mf1, mf2, mf3]
        end

        it 'sorts correctly by size' do
          uploader = create(:user)
          mf1 = create(:media_file_for_audio, size: 1500, uploader: uploader)
          mf2 = create(:media_file_for_audio, size: 3000, uploader: uploader)
          mf3 = create(:media_file_for_audio, size: 100, uploader: uploader)

          get(
            :index,
            params: { filter: { search_term: uploader.id }, sort_by: :size_desc },
            session: { user_id: admin_user.id }
          )

          expect(assigns[:media_files]).to eq [mf2, mf1, mf3]
        end
      end
    end
  end

  describe '#show' do
    before do
      request.env['HTTP_REFERER'] = '/media_files'
    end

    context 'when media file has not audio/video type' do
      before do
        get(
          :show,
          params: { id: media_file.id },
          session: { user_id: admin_user.id })
      end

      it 'responds with 200 HTTP status code' do
        expect(response).to be_successful
        expect(response).to have_http_status(200)
      end

      it 'assigns @media_file correctly' do
        expect(assigns[:media_file]).to eq media_file
      end

      it 'does not assigns @zencoder_jobs' do
        expect(assigns[:zencoder_jobs]).to be_nil
      end
    end

    context 'when media file has audio/video type' do
      it 'assigns @zencoder_jobs when necessary' do
        allow_any_instance_of(MediaFile)
          .to receive(:previews_zencoder?).and_return(true)

        get(
          :show,
          params: { id: media_file.id },
          session: { user_id: admin_user.id })

        expect(assigns[:zencoder_jobs]).to be
      end
    end
  end

  describe '#reencode' do
    before do
      allow_any_instance_of(ZencoderRequester).to receive(:process)
      post(
        :reencode,
        params: { id: media_file.id },
        session: { user_id: admin_user.id })
    end

    it 'redirects to media file show page' do
      expect(response).to redirect_to(media_file_path(media_file))
      expect(response).to have_http_status(302)
    end

    it 'sets info flash message' do
      expect(flash[:info]).not_to be_empty
    end
  end

  describe '#recreate_thumbnails' do
    let(:existing_thumbnail) { 'small' }

    shared_examples 'redirects to media file show page' do
      it 'redirects to media file show page' do
        expect(response).to redirect_to(media_file_path(media_file))
        expect(response).to have_http_status(302)
      end
    end

    shared_examples 'sets flash message' do |type|
      it "sets #{type} flash message" do
        expect(flash[type]).not_to be_empty
      end
    end

    shared_examples 'successful thumbnail recreation' do |expected_thumbnails|
      let(:media_file) do
        create(:media_file, media_file_attributes)
      end

      let!(:preview) do
        create(:preview,
               media_file: media_file,
               content_type: 'image/jpeg',
               media_type: 'image',
               filename: "#{media_file.guid}_#{existing_thumbnail}.jpg",
               thumbnail: existing_thumbnail)
      end
      let(:thumbnail_file) { preview.file_path }

      before do
        stub_preview_conversion(media_file)
        expect(File).to receive(:delete).with(thumbnail_file)

        post(
          :recreate_thumbnails,
          params: { id: media_file.id },
          session: { user_id: admin_user.id })
      end

      it 'destroys existing previews' do
        expect(Preview.exists?(preview.id)).to be false
      end

      it 'recreates the expected thumbnail sizes' do
        expect(media_file.reload.previews.pluck(:thumbnail))
          .to match_array(expected_thumbnails.map(&:to_s))
      end

      it_behaves_like 'redirects to media file show page'
      it_behaves_like 'sets flash message', :info
    end

    context 'when media file can create previews internally' do
      let(:media_file_attributes) { { height: 1500, width: 2000 } }

      it_behaves_like 'successful thumbnail recreation',
                      Madek::Constants::THUMBNAILS.keys
    end

    context 'when media file has an existing active thumbnail' do
      let(:media_file_attributes) { { height: 1500, width: 2000 } }
      let(:existing_thumbnail) { 'medium' }

      it_behaves_like 'successful thumbnail recreation',
                      Madek::Constants::THUMBNAILS.keys
    end

    context 'when PDF media file can create previews internally' do
      let(:media_file_attributes) do
        {
          content_type: 'application/pdf',
          extension: 'pdf',
          height: nil,
          media_type: 'document',
          width: nil
        }
      end

      it_behaves_like 'successful thumbnail recreation',
                      Madek::Constants::THUMBNAILS.keys
    end

    context 'when media file cannot create previews internally' do
      let(:media_file) { create(:media_file_for_audio) }
      let!(:preview) { create(:preview, media_file: media_file) }

      before do
        expect(controller).not_to receive(:recreate_thumbnail_files!)
        expect_any_instance_of(MediaFile)
          .not_to receive(:create_previews!)

        post(
          :recreate_thumbnails,
          params: { id: media_file.id },
          session: { user_id: admin_user.id })
      end

      it 'keeps existing previews' do
        expect(Preview.exists?(preview.id)).to be true
      end

      it_behaves_like 'redirects to media file show page'
      it_behaves_like 'sets flash message', :error
    end

    context 'when thumbnail recreation fails' do
      let(:media_file) do
        create(:media_file, height: 1500, width: 2000)
      end
      let!(:preview) { create(:preview, media_file: media_file) }
      let(:thumbnail_file) do
        preview.file_path
      end

      before do
        expect(File).to receive(:delete).with(thumbnail_file)
        allow_any_instance_of(MediaFile)
          .to receive(:create_previews!)
          .and_raise('conversion failed')

        post(
          :recreate_thumbnails,
          params: { id: media_file.id },
          session: { user_id: admin_user.id })
      end

      it 'deletes existing previews before recreating thumbnails' do
        expect(Preview.exists?(preview.id)).to be false
      end

      it_behaves_like 'redirects to media file show page'

      it 'sets error flash message with retry hint' do
        expect(flash[:error]).to include('conversion failed')
        expect(flash[:error]).to include('retry this action')
      end
    end

    context 'when old thumbnail files have permission-denied errors' do
      let(:media_file) do
        create(:media_file, height: 1500, width: 2000)
      end
      let!(:preview) do
        create(:preview,
               media_file: media_file,
               content_type: 'image/jpeg',
               filename: "#{media_file.guid}_small.jpg",
               media_type: 'image',
               thumbnail: 'small')
      end

      before do
        stub_preview_conversion(media_file)
        allow(File)
          .to receive(:delete)
          .with(preview.file_path)
          .and_raise(Errno::EACCES, 'permission denied')

        post(
          :recreate_thumbnails,
          params: { id: media_file.id },
          session: { user_id: admin_user.id })
      end

      it 'recreates previews despite permission-denied error' do
        expect(media_file.reload.previews.pluck(:thumbnail))
          .to match_array(Madek::Constants::THUMBNAILS.keys.map(&:to_s))
      end

      it_behaves_like 'redirects to media file show page'
      it_behaves_like 'sets flash message', :info
    end

    context 'when old preview rows cannot be deleted' do
      let(:media_file) do
        create(:media_file, height: 1500, width: 2000)
      end
      let!(:preview) do
        create(:preview,
               media_file: media_file,
               content_type: 'image/jpeg',
               filename: "#{media_file.guid}_medium.jpg",
               media_type: 'image',
               thumbnail: 'medium')
      end

      before do
        stub_preview_conversion(media_file)
        allow(controller)
          .to receive(:delete_preview_rows!)
          .and_raise('Expected to delete 1 previews, deleted 0.')
        expect(File).not_to receive(:delete).with(preview.file_path)
        expect_any_instance_of(MediaFile)
          .not_to receive(:create_previews!)

        post(
          :recreate_thumbnails,
          params: { id: media_file.id },
          session: { user_id: admin_user.id })
      end

      it 'keeps existing previews' do
        expect(Preview.exists?(preview.id)).to be true
      end

      it 'does not generate new previews' do
        expect(media_file.reload.previews.pluck(:id)).to eq [preview.id]
      end

      it_behaves_like 'redirects to media file show page'

      it 'sets error flash message' do
        expect(flash[:error]).to include('Expected to delete 1 previews')
      end
    end

    context 'when old thumbnail file deletion fails' do
      let(:media_file) do
        create(:media_file, height: 1500, width: 2000)
      end
      let!(:preview) do
        create(:preview,
               media_file: media_file,
               content_type: 'image/jpeg',
               filename: "#{media_file.guid}_small.jpg",
               media_type: 'image',
               thumbnail: 'small')
      end

      before do
        stub_preview_conversion(media_file)
        allow(File)
          .to receive(:delete)
          .with(preview.file_path)
          .and_raise('cleanup failed')
        expect_any_instance_of(MediaFile)
          .not_to receive(:create_previews!)

        post(
          :recreate_thumbnails,
          params: { id: media_file.id },
          session: { user_id: admin_user.id })
      end

      it 'deletes old preview rows before file cleanup' do
        expect(Preview.exists?(preview.id)).to be false
      end

      it_behaves_like 'redirects to media file show page'

      it 'sets error flash message' do
        expect(flash[:error]).to include('cleanup failed')
      end
    end

    context 'when old thumbnail files are on read-only storage' do
      let(:media_file) do
        create(:media_file, height: 1500, width: 2000)
      end
      let!(:preview) do
        create(:preview,
               media_file: media_file,
               content_type: 'image/jpeg',
               filename: "#{media_file.guid}_small.jpg",
               media_type: 'image',
               thumbnail: 'small')
      end

      before do
        stub_preview_conversion(media_file)
        allow(File)
          .to receive(:delete)
          .with(preview.file_path)
          .and_raise(Errno::EROFS, 'read-only file system')

        post(
          :recreate_thumbnails,
          params: { id: media_file.id },
          session: { user_id: admin_user.id })
      end

      it 'recreates previews on the first request' do
        expect(media_file.reload.previews.pluck(:thumbnail))
          .to match_array(Madek::Constants::THUMBNAILS.keys.map(&:to_s))
      end

      it_behaves_like 'redirects to media file show page'
      it_behaves_like 'sets flash message', :info
    end
  end

  def prepare_uploader(first_name, last_name)
    create(
      :user,
      person: create(
        :person,
        first_name: first_name,
        last_name: last_name
      )
    )
  end

  def stub_preview_conversion(media_file)
    allow(File).to receive(:exist?).and_call_original
    allow(File)
      .to receive(:exist?)
      .with(media_file.original_store_location)
      .and_return(true)
    allow(FileConversion).to receive(:convert)
    allow_any_instance_of(MediaFile)
      .to receive(:get_dimensions)
      .and_return(width: 100, height: 100)
  end
end
