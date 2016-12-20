require 'spec_helper'

describe MediaFilesController do
  let(:admin_user) { create :admin_user }
  let(:media_file) { create :media_file }

  describe '#index' do
    it 'prepares sorters' do
      get :index, {}, user_id: admin_user.id

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
          {
            filter: {
              search_term: 'foo.ogg',
              conversion_status: :missing
            }
          },
          user_id: admin_user.id
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
          {
            filter: {
              search_term: 'foo.mov',
              conversion_status: :failed
            }
          },
          user_id: admin_user.id
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
            {
              filter: { search_term: 'foo' },
              sort_by: :uploader_asc
            },
            user_id: admin_user.id
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
            { filter: { search_term: uploader.id }, sort_by: :media_type_asc },
            user_id: admin_user.id
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
            { filter: { search_term: uploader.id }, sort_by: :size_asc },
            user_id: admin_user.id
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
            {
              filter: { search_term: 'foo' },
              sort_by: :uploader_desc
            },
            user_id: admin_user.id
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
            { filter: { search_term: uploader.id }, sort_by: :media_type_desc },
            user_id: admin_user.id
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
            { filter: { search_term: uploader.id }, sort_by: :size_desc },
            user_id: admin_user.id
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
      before { get :show, { id: media_file.id }, user_id: admin_user.id }

      it 'responds with 200 HTTP status code' do
        expect(response).to be_success
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

        get :show, { id: media_file.id }, user_id: admin_user.id

        expect(assigns[:zencoder_jobs]).to be
      end
    end
  end

  describe '#reencode' do
    before do
      allow_any_instance_of(ZencoderRequester).to receive(:process)
      post :reencode, { id: media_file.id }, user_id: admin_user.id
    end

    it 'redirects to media file show page' do
      expect(response).to redirect_to(media_file_path(media_file))
      expect(response).to have_http_status(302)
    end

    it 'sets info flash message' do
      expect(flash[:info]).not_to be_empty
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
end
