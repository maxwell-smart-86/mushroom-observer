# frozen_string_literal: true

require "test_helper"

# NIMMO NOTE!!!! PARAM FOR SEQUENCE OBSERVATION HAS CHANGED FROM :id TO :obs !!!
# MUST CHANGE ALSO IN TESTS!!! - 08/20

# Controller tests for nucleotide sequences
class SequencesControllerTest < IntegrationControllerTestCase
  def test_index
    get sequences_path
    assert_template "sequences/index"
    assert :success
  end

  def test_search
    get sequences_path(pattern: Sequence.last.id)
    # follow_redirect!
    # @controller.instance_variable_get("@sequence")
    # byebug
    # assert_redirected_to sequence_path(Sequence.last.id)
    # puts response.body
    assert_template "sequences/show"
    assert :success
    assert_select "[data-sequence='#{Sequence.last.id}']"

    get sequences_path(pattern: "ITS")
    # puts response.body
    assert_template "sequences/index"
    assert :success
  end

  def test_observation_index
    obs = observations(:locally_sequenced_obs)
    get sequences_path(obs: obs.id)
    # puts response.body
    assert :success
    # note this must be a regexp, because there will be a query string after
    assert_select ":match('href', ?)", Regexp.new(observation_path(obs.id))

    obs = observations(:genbanked_obs)
    get sequences_path(obs: obs.id)
    # puts response.body
    assert :success
    assert_select ":match('href', ?)", Regexp.new(observation_path(obs.id))
  end

  def test_index_sequence
    obs = observations(:genbanked_obs)
    query = Query.lookup_and_save(:Sequence, :for_observation, observation: obs)
    results = query.results
    assert_operator(results.count, :>, 3)
    q = query.id.alphabetize

    get sequences_path(q: q, obs: results[2].id) # obs: was id:
    # puts response.body
    assert_response :success
  end

  def test_show
    # Prove sequence displayed if called with id of sequence in db
    sequence = sequences(:local_sequence)
    get sequence_path(id: sequence.id)
    puts response.body
    assert_template "sequences/show"
    assert_response :success
    assert_select "[data-sequence='#{sequence.id}']"

    # Prove index displayed if called with id of sequence not in db
    get sequence_path(id: 666)
    # assert_redirected_to(sequences_index_sequence_path)
    # puts response.body
    assert_template "sequences/index"
  end

  def test_show_next
    obs = observations(:genbanked_obs)
    query = Query.lookup_and_save(:Sequence, :for_observation, observation: obs)
    results = query.results
    q = query.id.alphabetize

    get sequence_path(q: q, id: results[1].id, next: 1)
    byebug
    # assert_redirected_to sequence_path(results[2], q: q)
    # puts response.body
    assert_template "sequences/show"
    assert_select "[data-sequence='#{results[2].id}']"
  end

  def test_show_prev
    obs = observations(:genbanked_obs)
    query = Query.lookup_and_save(:Sequence, :for_observation, observation: obs)
    results = query.results
    q = query.id.alphabetize

    get sequence_path(q: q, id: results[2].id, prev: 1)
    # assert_redirected_to sequence_path(results[1], q: q)
    # puts response.body
    assert_template("sequences/show")
    assert_select "[data-sequence='#{results[1].id}']"
  end

  def test_login
    # NOTE: check this method, may need adjusting for new form markup
    # get account_login_path
    # puts response.body

    login("zero")

  end

  def test_new
    obs   = observations(:minimal_unknown_obs)
    owner = obs.user

    # Prove method requires login
    get new_sequence_path(obs: obs.id)
    # NOTE assert_redirected_to doesn't work because
    # session_extensions#get already does follow_redirects!
    # assert_redirected_to account_login_path
    # NOTE assert_template is not a method in Integration tests
    # assert_template("account/login")
    # byebug
    assert_equal account_login_path, path

    # Prove logged-in user can add Sequence to someone else's Observation
    login("zero")
    get new_sequence_path, params: { obs: obs.id }
    # byebug
    assert_response :success

    # Prove Observation owner can add Sequence
    login(owner.login)
    get new_sequence_path, params: { obs: obs.id }
    assert_response :success

    # Prove admin can add Sequence
    make_admin("zero")
    get new_sequence_path, params: { obs: obs.id }
    assert_response :success
  end
  # test_new green - AN 08/20

  def test_create
    old_count = Sequence.count
    obs   = observations(:detailed_unknown_obs)
    owner = obs.user

    locus = "ITS"
    bases = "gagtatgtgc acacctgccg tctttatcta tccacctgtg cacacattgt agtcttgggg"\
            "gattggttag cgacaatttt tgttgccatg tcgtcctctg gggtctatgt tatcataaac"\
            "cacttagtat gtcgtagaat gaagtatttg ggcctcagtg cctataaaac aaaatacaac"\
            "tttcagcaac ggatctcttg gctctcgcat cgatgaagaa cgcagcgaaa tgcgataagt"\
            "aatgtgaatt gcagaattca gtgaatcatc gaatctttga acgcaccttg cgctccttgg"\
            "tattccgagg agcatgcctg tttgagtgtc attaaattct caacccctcc agcttttgtt"\
            "gctggtcgtg gcttggatat gggagtgttt gctggtctca ttcgagatca gctctcctga"\
            "aatacattag tggaaccgtt tgcgatccgt caccggtgtg ataattatct acgccataga"\
            "ctgtgaacgc tctctgtatt gttctgcttc taactgtctt attaaaggac aacaatattg"\
            "aacttttgac ctcaaatcag gtaggactac ccgctgaact taagcatatc aataa"
    params = {
      obs: obs.id,
      sequence: { locus: locus,
                  bases: bases }
    }

    # NOTE: the correct path is to POST to sequences_path.
    # with REST routing, new_*_path (blank form) accepts only GET requests.

    # The problem here is that the "post" method does not produce a
    # request where request.method == "POST". It's "GET"... to "account/login"

    # Prove user must be logged in to create Sequence
    puts "Prove user must be logged in to create Sequence"
    post sequences_path, params: params
    # assert_flash_error
    # byebug
    assert_equal(old_count, Sequence.count)

    # Prove logged-in user can add sequence to someone else's Observation
    puts "Prove logged-in user can add sequence to someone else's Observation"
    user = users(:zero_user)
    login(user.login)
    # byebug
    post sequences_path, params: params
    # OK this is not even hitting the :create action. Huh? - AN
    # byebug
    assert_equal(old_count + 1, Sequence.count)
    sequence = Sequence.last
    assert_objs_equal(obs, sequence.observation)
    assert_users_equal(user, sequence.user)
    assert_equal(locus, sequence.locus)
    assert_equal(bases, sequence.bases)
    assert_empty(sequence.archive)
    assert_empty(sequence.accession)

    # assert_redirected_to(observation_path(obs))
    assert_equal(observation_path(obs), path)

    assert_flash_success
    assert(obs.rss_log.notes.include?("log_sequence_added"),
           "Failed to include Sequence added in RssLog for Observation")

    # Prove user can create non-repository Sequence
    old_count = Sequence.count
    locus = "ITS"
    bases = "gagtatgtgc acacctgccg tctttatcta tccacctgtg cacacattgt agtcttgggg"
    params = {
      obs: obs.id, # obs: was id:
      sequence: { locus: locus,
                  bases: bases }
    }

    login(owner.login)
    post sequences_path(params)
    assert_equal(old_count + 1, Sequence.count)
    sequence = Sequence.last
    assert_objs_equal(obs, sequence.observation)
    assert_users_equal(owner, sequence.user)
    assert_equal(locus, sequence.locus)
    assert_equal(bases, sequence.bases)
    assert_empty(sequence.archive)
    assert_empty(sequence.accession)

    # assert_redirected_to(observation_path(obs))
    assert_equal(observation_path(obs), path)

    assert_flash_success
    assert(obs.rss_log.notes.include?("log_sequence_added"),
           "Failed to include Sequence added in RssLog for Observation")

    # Prove admin can create repository Sequence
    locus =     "ITS"
    archive =   "GenBank"
    accession = "KY366491.1"
    params = {
      obs: obs.id, # obs: was id:
      sequence: { locus: locus,
                  archive: archive,
                  accession: accession }
    }
    old_count = Sequence.count
    make_admin("zero")
    post sequences_path(params)
    assert_equal(old_count + 1, Sequence.count)
    sequence = Sequence.last
    assert_equal(locus, sequence.locus)
    assert_empty(sequence.bases)
    assert_equal(archive, sequence.archive)
    assert_equal(accession, sequence.accession)

    # assert_redirected_to(observation_path(obs))
    assert_equal(observation_path(obs), path)

  end

  def test_create_wrong_parameters
    old_count = Sequence.count
    obs = observations(:coprinus_comatus_obs)
    login(obs.user.login)

    # Prove that locus is required.
    params = {
      obs: obs.id, # obs: was id:
      sequence: { locus: "",
                  bases: "actgct" }
    }
    post sequences_path(params)
    assert_equal(old_count, Sequence.count)
    # response is :success because it just reloads the form
    assert_response(:success)
    assert_flash_error

    # Prove that bases or archive+accession required.
    params = {
      obs: obs.id, # obs: was id:
      sequence: { locus: "ITS" }
    }
    post sequences_path(params)
    assert_equal(old_count, Sequence.count)
    assert_response(:success)
    assert_flash_error

    # Prove that accession required if archive present.
    params = {
      obs: obs.id, # obs: was id:
      sequence: { locus: "ITS", archive: "GenBank" }
    }
    post sequences_path(params)
    assert_equal(old_count, Sequence.count)
    assert_response(:success)
    assert_flash_error

    # Prove that archive required if accession present.
    params = {
      obs: obs.id, # obs: was id:
      sequence: { locus: "ITS", accession: "KY133294.1" }
    }
    post sequences_path(params)
    assert_equal(old_count, Sequence.count)
    assert_response(:success)
    assert_flash_error
  end

  def test_make_redirect
    obs = observations(:genbanked_obs)
    query = Query.lookup_and_save(:Sequence, :all)
    q = query.id.alphabetize
    params = {
      obs: obs.id, # obs: was id:
      sequence: { locus: "ITS", bases: "atgc" },
      q: q
    }

    # Prove that query params are added to form action.
    login(obs.user.login)
    get new_sequence_path(params)
    assert_select("form input", { type: "hidden", name: "q", value: q })

    # Prove that post keeps query params intact.
    # FIXME - Check for the q somehow, since assert_redirected_to doesn't work?
    post sequences_path(params)
    # assert_redirected_to(observation_path(obs, q: q))
    # puts response.body
    # assert_template("observations/show")
    # puts "path"
    # pp path
    # puts "params_now"
    # pp params_now
    # puts "params"
    # pp params
    # byebug
    # puts "request.params"
    # pp request.params
    assert_equal request.params["q"], q
  end

  def test_edit
    sequence = sequences(:local_sequence)
    obs      = sequence.observation
    observer = obs.user

    # Prove method requires login
    assert_not_equal(rolf, observer)
    assert_not_equal(rolf, sequence.user)
    # requires_login(:edit, id: sequence.id)
    # requires_login(edit_sequence_path(id: sequence.id), account_login_path)
    # Should send you to back to the observation show page
    get(edit_sequence_path(id: sequence.id))
    assert_equal(account_login_path, path)

    # # Prove user cannot edit Sequence he didn't create for Obs he doesn't own
    login("zero")
    get edit_sequence_path(id: sequence.id)
    # # assert_redirected_to(observation_path(obs))
    # # puts response.body
    # # assert_template("observations/show")
    assert_equal(observation_path(sequence.observation.id), path)
    #
    # # Prove Observation owner can edit Sequence
    login(observer.login)
    get edit_sequence_path(id: sequence.id)
    assert_response(:success)
    #
    # # Prove admin can edit Sequence
    make_admin("zero")
    get edit_sequence_path(id: sequence.id)
    assert_response(:success)
  end

  def test_update
    sequence  = sequences(:local_sequence)
    obs       = sequence.observation
    observer  = obs.user
    sequencer = sequence.user

    locus = "mtSSU"
    bases = "gagtatgtgc acacctgccg tctttatcta tccacctgtg cacacattgt agtcttgggg"\
            "gattggttag cgacaatttt tgttgccatg tcgtcctctg gggtctatgt tatcataaac"\
            "cacttagtat gtcgtagaat gaagtatttg ggcctcagtg cctataaaac aaaatacaac"\
            "tttcagcaac ggatctcttg gctctcgcat cgatgaagaa cgcagcgaaa tgcgataagt"\
            "aatgtgaatt gcagaattca gtgaatcatc gaatctttga acgcaccttg cgctccttgg"\
            "tattccgagg agcatgcctg tttgagtgtc attaaattct caacccctcc agcttttgtt"\
            "gctggtcgtg gcttggatat gggagtgttt gctggtctca ttcgagatca gctctcctga"\
            "aatacattag tggaaccgtt tgcgatccgt caccggtgtg ataattatct acgccataga"\
            "ctgtgaacgc tctctgtatt gttctgcttc taactgtctt attaaaggac aacaatattg"\
            "aacttttgac ctcaaatcag gtaggactac ccgctgaact taagcatatc aataa"
    params = {
      id: sequence.id,
      sequence: { locus: locus,
                  bases: bases }
    }

    # Prove user must be logged in to edit Sequence.
    patch sequence_path(params)
    assert_not_equal(locus, sequence.reload.locus)

    # Prove user must be owner to edit Sequence.
    login("zero")
    patch sequence_path(params)
    assert_not_equal(locus, sequence.reload.locus)
    assert_flash_text(:permission_denied.t)

    # Prove Observation owner user can edit Sequence
    login(observer.login)
    patch sequence_path(params)
    sequence.reload
    obs.rss_log.reload
    assert_objs_equal(obs, sequence.observation)
    assert_users_equal(sequencer, sequence.user)
    assert_equal(locus, sequence.locus)
    assert_equal(bases, sequence.bases)
    assert_empty(sequence.archive)
    assert_empty(sequence.accession)
    # For once this is actually what you want
    assert_redirected_to(observation_path(obs.id))
    # # puts response.body
    # # assert_template("observations/show")
    # assert_equal(observation_path(obs.id), path)
    assert_flash_success
    assert(obs.rss_log.notes.include?("log_sequence_updated"),
           "Failed to include Sequence updated in RssLog for Observation")

    # Prove admin can accession Sequence
    archive   = "GenBank"
    accession = "KT968655"
    params = {
      id: sequence.id,
      sequence: { locus: locus,
                  bases: bases,
                  archive: archive,
                  accession: accession }
    }
    make_admin("zero")
    # byebug
    patch sequence_path(params)
    sequence.reload
    # byebug
    obs.rss_log.reload
    assert_equal(archive, sequence.archive)
    assert_equal(accession, sequence.accession)
    assert(obs.rss_log.notes.include?("log_sequence_accessioned"),
           "Failed to include Sequence accessioned in RssLog for Observation")

    # # Prove Observation owner user can edit locus
    # locus  = "ITS"
    # params = {
    #   id: sequence.id,
    #   sequence: { locus: locus,
    #               bases: bases,
    #               archive: archive,
    #               accession: accession }
    # }
    # patch sequence_path(params)
    # assert_equal(locus, sequence.reload.locus)
    #
    # # Prove locus required.
    # params = {
    #   id: sequence.id,
    #   sequence: { locus: "",
    #               bases: bases,
    #               archive: archive,
    #               accession: accession }
    # }
    # patch sequence_path(params)
    # # response is 200 because it just reloads the form
    # assert_response(:success)
    # assert_flash_error
    #
    # # Prove bases or archive+accession required.
    # params = {
    #   id: sequence.id,
    #   sequence: { locus: locus,
    #               bases: "",
    #               archive: "",
    #               accession: "" }
    # }
    # patch sequence_path(params)
    # assert_response(:success)
    # assert_flash_error
    #
    # # Prove accession required if archive present.
    # params = {
    #   id: sequence.id,
    #   sequence: { locus: locus,
    #               bases: bases,
    #               archive: archive,
    #               accession: "" }
    # }
    # patch sequence_path(params)
    # assert_response(:success)
    # assert_flash_error
    #
    # # Prove archive required if accession present.
    # params = {
    #   id: sequence.id,
    #   sequence: { locus: locus,
    #               bases: bases,
    #               archive: "",
    #               accession: accession }
    # }
    # patch sequence_path(params)
    # assert_response(:success)
    # assert_flash_error
  end

  def test_change_redirect
    obs      = observations(:genbanked_obs)
    sequence = obs.sequences[2]
    assert_operator(obs.sequences.count, :>, 3)
    query = Query.lookup_and_save(:Sequence, :for_observation, observation: obs)
    q     = query.id.alphabetize
    login(obs.user.login)
    params = {
      id: sequence.id,
      sequence: { locus: sequence.locus,
                  bases: sequence.bases,
                  archive: sequence.archive,
                  accession: sequence.accession }
    }

    # Prove that :edit passes "back" and query param through to form.
    get edit_sequence_path(params.merge(back: "foo", q: q))
    assert_select("form input", { type: "hidden", name: "back", value: "foo" })
    assert_select("form input", { type: "hidden", name: "q", value: q })

    # Prove by default :update goes back to observation.
    patch sequence_path(params)
    # assert_redirected_to(observation_path(obs))
    puts response.body
    assert_template("observations/show")

    # Prove that :update keeps query param when returning to observation.
    patch sequence_path(params.merge(q: q))
    # assert_redirected_to(observation_path(obs, q: q))
    puts response.body
    assert_template("observations/show")

    # Prove that :update can return to show, too, with query intact.
    patch sequence_path(params.merge(back: "show", q: q))
    # assert_redirected_to(sequence_path(sequence, q: q))
    puts response.body
    assert_template("sequences/show")
  end

  def test_destroy
    old_count = Sequence.count
    sequence = sequences(:local_sequence)
    obs      = sequence.observation
    observer = obs.user

    # Prove user must be logged in to destroy Sequence.
    delete sequence_path(id: sequence.id)
    assert_equal(old_count, Sequence.count)

    # Prove user cannot destroy Sequence he didn't create for Obs he doesn't own
    login("zero")
    delete sequence_path(id: sequence.id)
    assert_equal(old_count, Sequence.count)
    # assert_redirected_to(observation_path(obs))
    puts response.body
    assert_template("observations/show")
    assert_flash_text(:permission_denied.t)

    # Prove Observation owner can destroy Sequence
    login(observer.login)
    delete sequence_path(id: sequence.id)
    assert_equal(old_count - 1, Sequence.count)
    # assert_redirected_to(observation_path(obs))
    puts response.body
    assert_template("observations/show")
    assert_flash_success
    assert(obs.rss_log.notes.include?("log_sequence_destroy"),
           "Failed to include Sequence destroyed in RssLog for Observation")
  end

  def test_destroy_admin
    old_count = Sequence.count
    sequence = sequences(:local_sequence)
    obs      = sequence.observation
    observer = obs.user

    # Prove admin can destroy Sequence
    make_admin("zero")
    delete sequence_path(id: sequence.id)
    assert_equal(old_count - 1, Sequence.count)
    # assert_redirected_to(observation_path(obs))
    puts response.body
    assert_template("observations/show")
    assert_flash_success
    assert(obs.rss_log.notes.include?("log_sequence_destroy"),
           "Failed to include Sequence destroyed in RssLog for Observation")
  end

  def test_destroy_redirect
    obs   = observations(:genbanked_obs)
    seqs  = obs.sequences
    query = Query.lookup_and_save(:Sequence, :for_observation, observation: obs)
    q     = query.id.alphabetize
    login(obs.user.login)

    # Prove by default it goes back to observation.
    delete sequence_path(id: seqs[0].id)
    # assert_redirected_to(observation_path(obs))
    puts response.body
    assert_template("observations/show")

    # Prove that it keeps query param intact when returning to observation.
    delete sequence_path(id: seqs[1].id, q: q)
    # assert_redirected_to(observation_path(obs, q: q))
    puts response.body
    assert_template("observations/show")

    # Prove that it can return to index, too, with query intact.
    delete sequence_path(id: seqs[2].id, q: q, back: "index")
    # assert_redirected_to sequences_index_sequence_path(q: q)
    assert_template("sequences/index")
  end
end
