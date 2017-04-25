function [X,file_list,labels] = subsample(params,t_type)
% SUBSAMPLE subsample DTF features
% outputs:
%	X - cell of DTF features
%	labels - labels of corresponding DTF features
%	file_list - list of all files

X=cell(length(params.feat_list),1);
labels=[];

switch t_type
    case 'train'
        tt_list_dir=params.train_list_dir;%/ucfTrainTestlist
        reg_pattern='train*';
    case 'test'
        tt_list_dir=params.test_list_dir;
        reg_pattern='test*';
    otherwise
        error('Unknown file pattern!');
end

% extract training/test list
tt_list=[]; % train/test files
tlists=dir(fullfile(tt_list_dir,reg_pattern));%trainlist01.txt
for i=1:length(tlists)
    fid=fopen(fullfile(tt_list_dir,tlists(i).name));%dakai xunlian yangben wenjian
    tmp=textscan(fid,'%s%d');%xunlian yangben de tezheng yiji biaoqian
    tt_list=[tt_list;tmp{1}];%cun tezheng
    labels=[labels;tmp{2}];%cun biaoqian 
end

% Make sure all files are compressed
check_gzip_cmd=sprintf('sh ./gzip_dtf_files -i %s > /dev/null 2>&1',params.dtf_dir);
system(check_gzip_cmd);

switch t_type
    case 'train'
        % extract DTF data and set labels
        %try
        %	matlabpool close;
        %catch exception
        %end
        %matlabpool open 4
        HOG=[];%gei tezheng dingyi yige kongjuzhen 
        HOF=[];
        MBHx=[];
        MBHy=[];
        parfor i=1:length(tt_list)
            action=regexprep(tt_list{i},'/v_(\w*)\.avi','');
            act_dir=fullfile(params.dtf_dir,action);
            clip_name=regexprep(tt_list{i},'\.avi$',''); % get video clip name
            clip_name=regexprep(clip_name,'.*/','');
            dtf_file=fullfile(act_dir,[clip_name,'.features.gz']);
            
            
            [newHOG,newHOF,newMBHx,newMBHy]=extract_dtf_feats(dtf_file,params,params.DTF_subsample_num);
            %congwenjian zhong duqu dtf tezheng
            HOG=[HOG newHOG];
            HOF=[HOF newHOF];
            MBHx=[MBHx newMBHx];
            MBHy=[MBHy newMBHy];%keyi zai zichu baocun hog ,hof ,MBHx,MBHy
        end
        %matlabpool close
        %liyong Xlai cubnchu tezheng
        X{1}=HOG;
        clear HOG;
        X{2}=HOF;
        clear HOF;
        X{3}=MBHx;
        clear MBHx;
        X{4}=MBHy;%keyi zai ci chu bao cun X huoqu suoyou shipin pianduan de si zhong miao shu fu 
        clear MBHy;
    case 'test'
        % Do nothing for test videos
    otherwise
        error('Unknown file pattern!');
end

file_list=tt_list;

end
