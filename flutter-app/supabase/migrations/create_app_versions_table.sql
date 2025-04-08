-- Supabase 테이블 생성: app_versions
CREATE TABLE IF NOT EXISTS public.app_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version TEXT NOT NULL,
    required BOOLEAN DEFAULT false, -- 필수 업데이트 여부
    message TEXT, -- 업데이트 메시지
    android_link TEXT, -- 안드로이드 스토어 링크
    ios_link TEXT, -- iOS 스토어 링크
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- RLS(Row Level Security) 정책 설정
ALTER TABLE public.app_versions ENABLE ROW LEVEL SECURITY;

-- 익명 사용자에게도 조회 권한 부여
CREATE POLICY "Anyone can read app_versions" 
ON public.app_versions
FOR SELECT 
TO anon
USING (true);

-- 관리자만 수정 가능하도록 설정
CREATE POLICY "Only admins can modify app_versions" 
ON public.app_versions
FOR ALL 
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM auth.users
        WHERE auth.users.id = auth.uid()
        AND auth.users.role = 'admin'
    )
);

-- 테스트 데이터 추가
INSERT INTO public.app_versions (version, required, message, android_link, ios_link)
VALUES ('1.0.0', false, '첫 번째 버전', 'market://details?id=com.gnu.pingpong', 'https://apps.apple.com/app/id앱ID'); 