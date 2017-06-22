/* $RoughId: md5init.c,v 1.2 2001/07/13 19:49:10 knu Exp $ */
/* $Id: md5init.c 19020 2008-09-01 07:48:53Z nobu $ */

#include "digest.h"
#include "md5.h"

static const rb_digest_metadata_t md5 = {
    RUBY_DIGEST_API_VERSION,
    MD5_DIGEST_LENGTH,
    MD5_BLOCK_LENGTH,
    sizeof(MD5_CTX),
    (rb_digest_hash_init_func_t)MD5_Init,
    (rb_digest_hash_update_func_t)MD5_Update,
    (rb_digest_hash_finish_func_t)MD5_Finish,
};


/*
 * A class for calculating message digests using the MD5
 * Message-Digest Algorithm by RSA Data Security, Inc., described in
 * RFC1321.
 */
void Init_md5(void)
{
    VALUE mDigest, cDigest_Base, cDigest_MD5;

    rb_require("digest");

    mDigest = rb_path2class("Digest");
    cDigest_Base = rb_path2class("Digest::Base");

    cDigest_MD5 = rb_define_class_under(mDigest, "MD5", cDigest_Base);

    rb_ivar_set(cDigest_MD5, rb_intern("metadata"),
      Data_Wrap_Struct(rb_cObject, 0, 0, (void *)&md5));
}
