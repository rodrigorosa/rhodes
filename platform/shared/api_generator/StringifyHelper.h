#ifndef __RhoLib__StringifyHelper__
#define __RhoLib__StringifyHelper__

#include "common/RhoStd.h"
#include "common/RhoPort.h"
#include "common/AutoPointer.h"
#include "logging/RhoLog.h"
#include "ruby/ext/rho/rhoruby.h"
#include "common/StringConverter.h"

namespace rho
{
    namespace apiGenerator
    {
        class IStringSerializable
        {
        public:
            virtual ~IStringSerializable(void) {}
            virtual void toString(rho::String &buffer) const = 0;
        };
        
        class StringifyVector : public IStringSerializable
        {
        protected:
            rho::Vector<rho::String> m_vector;
            size_t m_bufferLen;
        public:
            StringifyVector() : m_bufferLen(0) {}
            
            void clear() { m_vector.clear(); m_bufferLen = 0; }
            
            void push_back(const rho::String& value, bool escape = true);
            
            void push_back(const bool& value) { push_back(rho::common::convertToStringA(value), true); }
            void push_back(const int& value) { push_back(rho::common::convertToStringA(value), true); }
            void push_back(const double& value) { push_back(rho::common::convertToStringA(value), true); }
            void push_back(const char* value) { push_back(rho::common::convertToStringA(value), true); }
            void push_back(const IStringSerializable& value);
            
            template<typename U>
            void fromVector(const rho::Vector<U> &u) {
                for(typename rho::Vector<U>::const_iterator iter = u.begin(); iter != u.end(); iter++ )
                {
                    push_back(*iter);
                }
            }
            
            virtual void toString(rho::String &buffer) const;
        };
        
        class StringifyHash : public IStringSerializable
        {
        protected:
            rho::Hashtable<rho::String, rho::String> m_hash;
            size_t m_bufferLen;
        public:
            StringifyHash() : m_bufferLen(0) {}
            
            void clear() { m_hash.clear(); m_bufferLen = 0; }
            
            void set(const rho::String& key, const rho::String& value, bool escape = true);
            
            void set(const rho::String& key, const bool& value) { set(key, rho::common::convertToStringA(value), true); }
            void set(const rho::String& key, const int& value) { set(key, rho::common::convertToStringA(value), true); }
            void set(const rho::String& key, const double& value) { set(key, rho::common::convertToStringA(value), true); }
            void set(const rho::String& key, const char* value) { set(key, rho::common::convertToStringA(value), true); }
            void set(const rho::String& key, const IStringSerializable& value);
            
            template<typename U>
            void fromHash(const rho::Hashtable<rho::String, U> &u) {
                for(typename rho::Hashtable<rho::String, U>::const_iterator iter = u.begin(); iter != u.end(); iter++ )
                {
                    set(iter->first,iter->second);
                }
            }
            
            virtual void toString(rho::String &buffer) const;
        };
    }
}


#endif /* defined(__RhoLib__StringifyHelper__) */
