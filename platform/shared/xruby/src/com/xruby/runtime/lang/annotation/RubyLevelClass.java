/**
 * Copyright 2007 Ye Zheng
 * Distributed under the BSD License
 */

package com.xruby.runtime.lang.annotation;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
public @interface RubyLevelClass {
	String name();
	String superclass() default "Object";
	String[] modules() default {};
	UndefMethod[] undef() default {};
	DummyMethod[] dummy() default {};
}