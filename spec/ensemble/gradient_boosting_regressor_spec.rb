# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rumale::Ensemble::GradientBoostingRegressor do
  let(:x) { Marshal.load(File.read(__dir__ + '/../test_samples.dat')) }
  let(:y) { x[true, 0] + x[true, 1]**2 }
  let(:y_mult) { Numo::DFloat[x[true, 0].to_a, (x[true, 1]**2).to_a].transpose.dot(Numo::DFloat[[0.6, 0.4], [0.0, 0.1]]) }
  let(:n_samples) { x.shape[0] }
  let(:n_features) { x.shape[1] }
  let(:n_outputs) { y_mult.shape[1] }
  let(:n_estimators) { 10 }
  let(:estimator) { described_class.new(n_estimators: n_estimators, learning_rate: 0.9, reg_lambda: 0.001, max_features: 1, random_seed: 9) }

  it 'learns the model for single regression problem.' do
    estimator.fit(x, y)
    leaf_ids = estimator.apply(x)
    predicted = estimator.predict(x)
    expect(estimator.params[:n_estimators]).to eq(n_estimators)
    expect(estimator.params[:max_features]).to eq(1)
    expect(estimator.estimators.class).to eq(Array)
    expect(estimator.estimators[0].class).to eq(Rumale::Tree::GradientTreeRegressor)
    expect(estimator.estimators.size).to eq(n_estimators)
    expect(estimator.feature_importances.class).to eq(Numo::DFloat)
    expect(estimator.feature_importances.shape[0]).to eq(n_features)
    expect(estimator.feature_importances.shape[1]).to be_nil
    expect(predicted.class).to eq(Numo::DFloat)
    expect(predicted.shape[0]).to eq(n_samples)
    expect(predicted.shape[1]).to be_nil
    expect(estimator.score(x, y)).to be_within(0.02).of(1.0)
    expect(leaf_ids.class).to eq(Numo::Int32)
    expect(leaf_ids.shape).to eq([n_samples, n_estimators])
  end

  it 'learns the model for multiple regression problem.' do
    estimator.fit(x, y_mult)
    leaf_ids = estimator.apply(x)
    predicted = estimator.predict(x)
    expect(estimator.estimators.class).to eq(Array)
    expect(estimator.estimators[0].class).to eq(Array)
    expect(estimator.estimators[0][0].class).to eq(Rumale::Tree::GradientTreeRegressor)
    expect(estimator.estimators.size).to eq(n_outputs)
    expect(estimator.estimators[0].size).to eq(n_estimators)
    expect(estimator.feature_importances.class).to eq(Numo::DFloat)
    expect(estimator.feature_importances.shape[0]).to eq(n_features)
    expect(estimator.feature_importances.shape[1]).to be_nil
    expect(predicted.class).to eq(Numo::DFloat)
    expect(predicted.shape[0]).to eq(n_samples)
    expect(predicted.shape[1]).to eq(n_outputs)
    expect(estimator.score(x, y_mult)).to be_within(0.02).of(1.0)
    expect(leaf_ids.class).to eq(Numo::Int32)
    expect(leaf_ids.shape).to eq([n_samples, n_estimators, n_outputs])
  end

  it 'returns leaf index that each sample reached.' do
    estimator.fit(x, y)
    index_mat = estimator.apply(x)
    expect(index_mat.shape[0]).to eq(n_samples)
    expect(index_mat.shape[1]).to eq(n_estimators)
    expect(index_mat[true, 0]).to eq(estimator.estimators[0].apply(x))
  end

  it 'dumps and restores itself using Marshal module.' do
    estimator.fit(x, y)
    copied = Marshal.load(Marshal.dump(estimator))
    expect(estimator.class).to eq(copied.class)
    expect(estimator.params).to match(copied.params)
    expect(estimator.estimators.size).to eq(copied.estimators.size)
    expect(estimator.feature_importances).to eq(copied.feature_importances)
    expect(estimator.rng).to eq(copied.rng)
    expect(estimator.score(x, y)).to eq(copied.score(x, y))
  end
end
