function [ pca_coeff, gmm, all_train_files, all_train_labels, all_test_files, all_test_labels ] = pretrain(params)
%PRETRAIN  Subsample DTF features, calculate PCA coefficients and train GMM model
%   Inputs:
%       params - structure of parameters
%       t_type - 'train' or 'test'
%
%   Outputs:
%       pca_coeff - PCA coefficients for each DTF feature
%       gmm - GMM params for each DTF feature

% To construct Fisher vector, fist to estimate the parameters of GMM.
% To estimate GMM params, subsampling vectors from DTF descriptors.

gmm_params.cluster_count=params.K;
gmm_params.maxcomps=gmm_params.cluster_count/4;
gmm_params.GMM_init= 'kmeans';
gmm_params.pnorm = single(2);    % L2 normalization, 0 to disable
gmm_params.subbin_norm_type = 'l2';
gmm_params.norm_type = 'l2';
gmm_params.post_norm_type = 'none';
gmm_params.pool_type = 'sum';
gmm_params.quad_divs = 2;
gmm_params.horiz_divs = 3;
gmm_params.kermap = 'hellinger';

dtf_feat_num=length(params.feat_list);%hog/hof/mbhx/mbhy
pca_coeff=cell(dtf_feat_num,1); % PCA coeficients
gmm=cell(dtf_feat_num,1);   % GMM parameters

feat_sample_train=params.train_sample_data;%/dtf_fisher-master/data/UCF101_train_data*.mat
feat_sample_test=params.test_sample_data;%/dtf_fisher-master/data/UCF101_test_data*.mat

fprintf('Subsampling DTF features ...\n');
if ~exist(feat_sample_train,'file')

    [feats_train, all_train_files, all_train_labels]=subsample(params,'train');
    save(feat_sample_train, 'feats_train','all_train_labels','all_train_files','-v7.3');
else
    load(feat_sample_train);
end

if ~exist(feat_sample_test,'file')
    [~, all_test_files, all_test_labels]=subsample(params,'test');%if .mat is not exist ,will new in subsample
    save(feat_sample_test,'all_test_labels','all_test_files','-v7.3');
else
    load(feat_sample_test);
end

for i=1:dtf_feat_num
	feat=feats_train{i};%feats_train=4*1 cell {96*985double}{108*985double}{96*985double}{96*985double}
	
	% L1 normalization & Square root
	feat=sqrt(feat/norm(feat,1));
	
	% Do PCA on train/test data to half-size original descriptors
	fprintf('Doing PCA ...\n');
	pca_coeff{i} = princomp(feat');
	pca_coeff{i} = pca_coeff{i}(:, 1:floor(size(feat,1)/2))';
	% dimensionality reduction
	feat = pca_coeff{i} * feat;%jiangwei zhihou de tezhengshu 48*764798

	fprintf('Training Guassian Mixture Model ...\n');
	gmm{i}=gmm_gen_codebook(feat,gmm_params);
end

end

