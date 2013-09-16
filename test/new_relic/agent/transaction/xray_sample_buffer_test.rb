# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/rpm/blob/master/LICENSE for complete details.

require File.expand_path(File.join(File.dirname(__FILE__),'..','..','..','test_helper'))

class NewRelic::Agent::Transaction
  class XraySampleBufferTest < Test::Unit::TestCase

    XRAY_SESSION_ID = 123
    MATCHING_TRANSACTION = "Matching/transaction/name"

    def setup
      @xray_sessions = stub
      @xray_sessions.stubs(:session_id_for_transaction_name).with(any_parameters).returns(nil)
      @xray_sessions.stubs(:session_id_for_transaction_name).with(MATCHING_TRANSACTION).returns(XRAY_SESSION_ID)

      @buffer = XraySampleBuffer.new
      @buffer.xray_sessions = @xray_sessions
    end

    def test_doesnt_store_if_not_matching_transaction
      sample = sample_with(:transaction_name => "Meaningless/transaction/name")
      @buffer.store(sample)

      assert @buffer.samples.empty?
    end

    def test_stores_if_matching_transaction
      sample = sample_with(:transaction_name => MATCHING_TRANSACTION)
      @buffer.store(sample)

      assert_equal([sample], @buffer.samples)
    end

    def test_stores_and_marks_xray_session_id
      sample = sample_with(:transaction_name => MATCHING_TRANSACTION)
      @buffer.store(sample)

      assert_equal(XRAY_SESSION_ID, sample.xray_session_id)
    end

    def test_limits_xray_traces
      tons_o_samples = XraySampleBuffer::MAX_SAMPLES * 2
      samples = (0..tons_o_samples).map do |i|
        sample = sample_with(:transaction_name => MATCHING_TRANSACTION)
        @buffer.store(sample)
        sample
      end

      assert_equal(samples.first(XraySampleBuffer::MAX_SAMPLES), @buffer.samples)
    end

    def sample_with(opts={})
      sample = NewRelic::TransactionSample.new
      sample.transaction_name = opts[:transaction_name]
      sample
    end

  end
end